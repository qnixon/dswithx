--  k-nearest neighbors classification, using only Ada's standard library.
--
--  Each test seed is labelled with the majority variety among its K nearest
--  training seeds, by Euclidean distance. There is no classifier to avoid;
--  sorting uses Generic_Array_Sort, and the votes are counted in a loop.

with Ada.Text_IO;                use Ada.Text_IO;
with Ada.Long_Float_Text_IO;     use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Ada.Strings.Unbounded;      use Ada.Strings.Unbounded;
with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;
with Ada.Containers.Vectors;
with Ada.Containers.Generic_Array_Sort;

procedure Main is
   K : constant := 5;

   --  A record groups one seed's measurements with its variety. A plain
   --  String has a fixed length, so the variety is an Unbounded_String.
   type Seed is record
      Length_Mm, Width_Mm : Long_Float;
      Variety             : Unbounded_String;
   end record;
   package Seed_Vectors is new Ada.Containers.Vectors (Positive, Seed);
   use Seed_Vectors;

   --  A training seed's distance from the test seed, and its row in Train.
   type Neighbor is record
      Distance : Long_Float;
      Row      : Positive;
   end record;
   type Neighbor_Array is array (Positive range <>) of Neighbor;

   --  GNAT's Generic_Array_Sort is a heapsort, which doesn't keep equal
   --  elements in order, so equal distances fall back to file order.
   function Nearer (A, B : Neighbor) return Boolean is
     (A.Distance < B.Distance
      or else (A.Distance = B.Distance and then A.Row < B.Row));
   procedure Sort is new Ada.Containers.Generic_Array_Sort
     (Positive, Neighbor, Neighbor_Array, Nearer);

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

   --  The number of the header field called Name.
   function Column (Header, Name : String) return Positive is
   begin
      for C in 1 .. Ada.Strings.Fixed.Count (Header, ",") + 1 loop
         if Field (Header, C) = Name then
            return C;
         end if;
      end loop;
      raise Constraint_Error with "column not found: " & Name;
   end Column;

   function Classify (Point : Seed; Train : Vector) return Unbounded_String is
      Neighbors  : Neighbor_Array (1 .. Natural (Train.Length));
      Best       : Unbounded_String;
      Best_Votes : Natural := 0;
   begin
      for I in Neighbors'Range loop
         Neighbors (I) :=
           (Distance => Sqrt ((Point.Length_Mm - Train (I).Length_Mm) ** 2 +
                              (Point.Width_Mm - Train (I).Width_Mm) ** 2),
            Row      => I);
      end loop;
      Sort (Neighbors);

      --  Count each of the K nearest labels' votes among the K; the first
      --  label to reach the highest count wins.
      for I in 1 .. K loop
         declare
            Label : constant Unbounded_String :=
              Train (Neighbors (I).Row).Variety;
            Votes : Natural := 0;
         begin
            for J in 1 .. K loop
               if Train (Neighbors (J).Row).Variety = Label then
                  Votes := Votes + 1;
               end if;
            end loop;
            if Votes > Best_Votes then
               Best := Label;
               Best_Votes := Votes;
            end if;
         end;
      end loop;
      return Best;
   end Classify;

   File        : File_Type;
   Train, Test : Vector;
   Correct     : Natural := 0;
begin
   Open (File, In_File, Ada.Command_Line.Argument (1));
   declare
      Header    : constant String := Get_Line (File);
      Length_C  : constant Positive := Column (Header, "length_mm");
      Width_C   : constant Positive := Column (Header, "width_mm");
      Variety_C : constant Positive := Column (Header, "variety");
      Split_C   : constant Positive := Column (Header, "split");
   begin
      while not End_Of_File (File) loop
         declare
            Line : constant String := Get_Line (File);
            S    : constant Seed :=
              (Length_Mm => Long_Float'Value (Field (Line, Length_C)),
               Width_Mm  => Long_Float'Value (Field (Line, Width_C)),
               Variety   => To_Unbounded_String (Field (Line, Variety_C)));
         begin
            if Field (Line, Split_C) = "train" then
               Train.Append (S);
            else
               Test.Append (S);
            end if;
         end;
      end loop;
   end;
   Close (File);

   for S of Test loop
      if Classify (S, Train) = S.Variety then
         Correct := Correct + 1;
      end if;
   end loop;

   Put_Line ("train_count" & Train.Length'Image);
   Put_Line ("test_count" & Test.Length'Image);
   Put_Line ("correct" & Correct'Image);
   Put ("accuracy ");
   Put (Long_Float (Correct) / Long_Float (Test.Length),
        Fore => 1, Aft => 6, Exp => 0);
   New_Line;
end Main;
