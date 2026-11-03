--  A decision tree classifier (CART with Gini impurity), using only Ada's
--  standard library.
--
--  Grows a tree on the training days by always making the split that leaves
--  the two sides purest, then predicts rain for the test days. Prints the
--  tree in preorder: each node is either a split (feature and threshold) or
--  a leaf (its prediction). Ada has no decision tree or classifier to skip.

with Ada.Text_IO;                use Ada.Text_IO;
with Ada.Long_Float_Text_IO;     use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Characters.Handling;    use Ada.Characters.Handling;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Ada.Containers.Vectors;
with Ada.Containers.Generic_Array_Sort;

procedure Main is
   type Feature is (Humidity, Pressure, Wind);   --  also the column names
   type Features is array (Feature) of Long_Float;

   type Day is record
      X    : Features;
      Rain : Boolean;
   end record;
   type Day_Array is array (Positive range <>) of Day;
   package Day_Vectors is new Ada.Containers.Vectors (Positive, Day);

   function To_Array (V : Day_Vectors.Vector) return Day_Array is
     [for I in 1 .. Natural (V.Length) => V (I)];

   type Float_Array is array (Positive range <>) of Long_Float;
   procedure Sort is new Ada.Containers.Generic_Array_Sort
     (Positive, Long_Float, Float_Array);

   Max_Depth : constant := 3;
   Min_Size  : constant := 5;

   --  A variant record: the discriminant Is_Leaf, fixed when a node is
   --  made, decides which fields the node has. A Node_Access points to a
   --  node, so a split can hold its children. The first line announces
   --  Node (an incomplete declaration) so that Node_Access can name it.
   type Node (Is_Leaf : Boolean);
   type Node_Access is access Node;
   type Node (Is_Leaf : Boolean) is record
      case Is_Leaf is
         when True =>
            Rain : Boolean;
         when False =>
            On          : Feature;
            Threshold   : Long_Float;
            Left, Right : Node_Access;
      end case;
   end record;

   --  The text of field number Col (counting from 1) in a CSV line.
   function Field (Line : String; Col : Positive) return String is
      Start : Positive := Line'First;
   begin
      for I in 1 .. Col - 1 loop
         Start := Index (Line (Start .. Line'Last), ",") + 1;
      end loop;
      declare
         Stop : constant Natural := Index (Line (Start .. Line'Last), ",");
      begin
         return (if Stop = 0 then Line (Start .. Line'Last)
                 else Line (Start .. Stop - 1));
      end;
   end Field;

   function Column (Header, Name : String) return Positive is
   begin
      for C in 1 .. Ada.Strings.Fixed.Count (Header, ",") + 1 loop
         if Field (Header, C) = Name then
            return C;
         end if;
      end loop;
      raise Constraint_Error with "column not found: " & Name;
   end Column;

   procedure Read (Path : String; Train, Test : out Day_Vectors.Vector) is
      File : File_Type;
   begin
      Open (File, In_File, Path);
      declare
         Header : constant String := Get_Line (File);
         --  F'Image is an enumeration value's name in capitals: "WIND".
         Cols : constant array (Feature) of Positive :=
           [for F in Feature => Column (Header, To_Lower (F'Image))];
         Rain_Col  : constant Positive := Column (Header, "rain");
         Split_Col : constant Positive := Column (Header, "split");
      begin
         while not End_Of_File (File) loop
            declare
               Line : constant String := Get_Line (File);
               D    : Day;
            begin
               for F in Feature loop
                  D.X (F) := Long_Float'Value (Field (Line, Cols (F)));
               end loop;
               D.Rain := Field (Line, Rain_Col) = "yes";
               if Field (Line, Split_Col) = "train" then
                  Train.Append (D);
               else
                  Test.Append (D);
               end if;
            end;
         end loop;
      end;
      Close (File);
   end Read;

   function Yes_Count (Days : Day_Array) return Natural is
      N : Natural := 0;
   begin
      for D of Days loop
         if D.Rain then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Yes_Count;

   --  Chance that two days drawn at random (with replacement) disagree.
   function Gini (Days : Day_Array) return Long_Float is
      P : constant Long_Float :=
        Long_Float (Yes_Count (Days)) / Long_Float (Days'Length);
   begin
      return 1.0 - P * P - (1.0 - P) * (1.0 - P);
   end Gini;

   --  An even split predicts "no".
   function Majority (Days : Day_Array) return Boolean is
     (2 * Yes_Count (Days) > Days'Length);

   --  The days on one side of a threshold: Left means X (F) <= T.
   function Side (Days : Day_Array; F : Feature; T : Long_Float;
                  Left : Boolean) return Day_Array is
      Kept : Day_Vectors.Vector;
   begin
      for D of Days loop
         if (D.X (F) <= T) = Left then
            Kept.Append (D);
         end if;
      end loop;
      return To_Array (Kept);
   end Side;

   --  Features are tried in order and thresholds from smallest to largest;
   --  only a strictly lower weighted Gini replaces the best so far.
   procedure Best_Split (Days : Day_Array; Found : out Boolean;
                         Score : out Long_Float; On : out Feature;
                         Threshold : out Long_Float) is
   begin
      Found := False;
      Score := Long_Float'Last;
      On := Feature'First;
      Threshold := 0.0;
      for F in Feature loop
         declare
            Values : Float_Array := [for I in Days'Range => Days (I).X (F)];
         begin
            Sort (Values);
            for I in Values'First .. Values'Last - 1 loop
               if Values (I) /= Values (I + 1) then   --  skip repeats
                  declare
                     T : constant Long_Float :=
                       (Values (I) + Values (I + 1)) / 2.0;
                     L : constant Day_Array := Side (Days, F, T, True);
                     R : constant Day_Array := Side (Days, F, T, False);
                     S : constant Long_Float :=
                       (Long_Float (L'Length) * Gini (L)
                        + Long_Float (R'Length) * Gini (R))
                       / Long_Float (Days'Length);
                  begin
                     if S < Score then
                        Found := True;
                        Score := S;
                        On := F;
                        Threshold := T;
                     end if;
                  end;
               end if;
            end loop;
         end;
      end loop;
   end Best_Split;

   function Grow (Days : Day_Array; Depth : Natural) return Node_Access is
      Found     : Boolean;
      Score, T  : Long_Float;
      F         : Feature;
      Impurity  : constant Long_Float := Gini (Days);
      function Leaf return Node_Access is
        (new Node'(Is_Leaf => True, Rain => Majority (Days)));
   begin
      if Impurity = 0.0 or Days'Length < Min_Size or Depth = Max_Depth then
         return Leaf;
      end if;
      Best_Split (Days, Found, Score, F, T);
      if not Found or Score >= Impurity then
         return Leaf;   --  no split makes the sides purer
      end if;
      return new Node'(Is_Leaf   => False, On => F, Threshold => T,
                       Left  => Grow (Side (Days, F, T, True), Depth + 1),
                       Right => Grow (Side (Days, F, T, False), Depth + 1));
   end Grow;

   function Predict (Tree : Node_Access; X : Features) return Boolean is
      N : Node_Access := Tree;
   begin
      while not N.Is_Leaf loop
         N := (if X (N.On) <= N.Threshold then N.Left else N.Right);
      end loop;
      return N.Rain;
   end Predict;

   procedure Say (Name : String; Value : Long_Float) is
   begin
      Put (Name & " ");
      Put (Value, Fore => 1, Aft => 6, Exp => 0);   --  six decimals, no E
      New_Line;
   end Say;

   K, Leaves : Natural := 0;

   --  Number each node in preorder and print it.
   procedure Print (N : Node_Access) is
   begin
      K := K + 1;
      declare
         Name : constant String := "node_" & Trim (K'Image, Ada.Strings.Left);
      begin
         if N.Is_Leaf then
            Put_Line (Name & "_predict " & (if N.Rain then "yes" else "no"));
            Leaves := Leaves + 1;
         else
            Put_Line (Name & "_feature " & To_Lower (N.On'Image));
            Say (Name & "_threshold", N.Threshold);
            Print (N.Left);
            Print (N.Right);
         end if;
      end;
   end Print;

   function Correct (Tree : Node_Access; Days : Day_Array) return Natural is
      N : Natural := 0;
   begin
      for D of Days loop
         if Predict (Tree, D.X) = D.Rain then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Correct;

   Train_V, Test_V : Day_Vectors.Vector;
begin
   Read (Ada.Command_Line.Argument (1), Train_V, Test_V);
   declare
      Train : constant Day_Array := To_Array (Train_V);
      Test  : constant Day_Array := To_Array (Test_V);
      Tree  : constant Node_Access := Grow (Train, 0);
      Hits  : constant Natural := Correct (Tree, Test);
   begin
      Put_Line ("train_count" & Train'Length'Image);
      Put_Line ("test_count" & Test'Length'Image);
      Print (Tree);
      Put_Line ("leaves" & Leaves'Image);
      Say ("train_accuracy",
           Long_Float (Correct (Tree, Train)) / Long_Float (Train'Length));
      Put_Line ("correct" & Hits'Image);
      Say ("accuracy", Long_Float (Hits) / Long_Float (Test'Length));
   end;
end Main;
