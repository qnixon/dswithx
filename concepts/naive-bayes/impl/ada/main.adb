--  Categorical naive Bayes with add-one (Laplace) smoothing, using only
--  Ada's standard library.
--
--  Learns P(label) and P(feature value | label) by counting training rows,
--  then labels each test row with the label that has the highest
--  log-probability. Ada has no naive Bayes routine, so there is no built-in
--  to avoid.

with Ada.Text_IO;                use Ada.Text_IO;
with Ada.Long_Float_Text_IO;     use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Characters.Handling;   use Ada.Characters.Handling;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;
with Ada.Containers.Indefinite_Vectors;
with Ada.Containers.Indefinite_Ordered_Maps;
with Ada.Containers.Indefinite_Ordered_Sets;

procedure Main is
   --  "Indefinite" containers hold Strings of any length.
   package Line_Vectors is new Ada.Containers.Indefinite_Vectors
     (Positive, String);
   package Count_Maps is new Ada.Containers.Indefinite_Ordered_Maps
     (String, Natural);
   package String_Sets is new Ada.Containers.Indefinite_Ordered_Sets (String);

   --  The feature columns, as an enumeration. Feature'Image (Has_Link) is
   --  "HAS_LINK", so the header is matched in lower case.
   type Feature is (Has_Link, Mentions_Money, Known_Sender);

   function Name (F : Feature) return String is (To_Lower (Feature'Image (F)));

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

   File        : File_Type;
   Rows        : Line_Vectors.Vector;
   Feature_Col : array (Feature) of Natural := [others => 0];
   Label_Col, Split_Col : Natural := 0;

   --  Counts keyed by one string: "label" or "feature=value|label".
   Counts      : Count_Maps.Map;
   Labels      : String_Sets.Set;   --  an ordered set iterates alphabetically
   Values      : array (Feature) of String_Sets.Set;
   Train_Count, Test_Count, Correct : Natural := 0;

   function Key (F : Feature; Row, Label : String) return String is
     (Name (F) & "=" & Field (Row, Feature_Col (F)) & "|" & Label);

   --  A missing key counts as zero.
   function Count_Of (K : String) return Natural is
     (if Counts.Contains (K) then Counts (K) else 0);

   procedure Add_One (K : String) is
   begin
      Counts.Include (K, Count_Of (K) + 1);   --  Include inserts or replaces
   end Add_One;

   function Log_Score (Row, Label : String) return Long_Float is
      Label_Count : constant Natural := Count_Of (Label);
      --  Logs turn the product of probabilities into a sum, avoiding
      --  underflow.
      Score : Long_Float :=
        Log (Long_Float (Label_Count) / Long_Float (Train_Count));
   begin
      for F in Feature loop
         --  Add-one smoothing: an unseen value never gets probability zero.
         Score := Score + Log
           (Long_Float (Count_Of (Key (F, Row, Label)) + 1)
            / Long_Float (Label_Count + Natural (Values (F).Length)));
      end loop;
      return Score;
   end Log_Score;

   --  Labels come out of the set in order, and only a strictly higher score
   --  replaces the best, so an exact tie goes to the first.
   function Classify (Row : String) return String is
      Best : String_Sets.Cursor := Labels.First;   --  a cursor marks a label
   begin
      for Position in Labels.Iterate loop
         if Log_Score (Row, String_Sets.Element (Position))
            > Log_Score (Row, String_Sets.Element (Best))
         then
            Best := Position;
         end if;
      end loop;
      return String_Sets.Element (Best);
   end Classify;
begin
   Open (File, In_File, Ada.Command_Line.Argument (1));
   declare
      Header : constant String := Get_Line (File);
   begin
      for C in 1 .. Ada.Strings.Fixed.Count (Header, ",") + 1 loop
         for F in Feature loop
            if Field (Header, C) = Name (F) then
               Feature_Col (F) := C;
            end if;
         end loop;
         if Field (Header, C) = "label" then
            Label_Col := C;
         elsif Field (Header, C) = "split" then
            Split_Col := C;
         end if;
      end loop;
   end;
   if Label_Col = 0 or else Split_Col = 0
     or else (for some C of Feature_Col => C = 0)
   then
      raise Constraint_Error with "missing column";
   end if;
   while not End_Of_File (File) loop
      declare
         Line : constant String := Get_Line (File);
      begin
         if Line /= "" then
            Rows.Append (Line);
         end if;
      end;
   end loop;
   Close (File);

   --  Training: count each label, and each feature value within a label.
   for Row of Rows loop
      if Field (Row, Split_Col) = "train" then
         Train_Count := Train_Count + 1;
         Add_One (Field (Row, Label_Col));
         Labels.Include (Field (Row, Label_Col));   --  ignored if present
         for F in Feature loop
            Add_One (Key (F, Row, Field (Row, Label_Col)));
            Values (F).Include (Field (Row, Feature_Col (F)));
         end loop;
      end if;
   end loop;
   if Train_Count = 0 then
      raise Constraint_Error with "no training rows";
   end if;

   for Row of Rows loop
      if Field (Row, Split_Col) = "test" then
         Test_Count := Test_Count + 1;
         if Classify (Row) = Field (Row, Label_Col) then
            Correct := Correct + 1;
         end if;
      end if;
   end loop;

   Put_Line ("train_count" & Natural'Image (Train_Count));
   Put_Line ("test_count" & Natural'Image (Test_Count));
   Put_Line ("correct" & Natural'Image (Correct));
   Put ("accuracy ");
   Put (Long_Float (Correct) / Long_Float (Test_Count),
        Fore => 1, Aft => 6, Exp => 0);   --  six decimals, no E
   New_Line;
end Main;
