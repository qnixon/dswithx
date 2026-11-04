--  Exact two-sided permutation test for a difference in means, using only
--  Ada's standard library.
--
--  If compost made no difference, the "compost" and "control" labels are
--  arbitrary, and any 8 of the 16 plants could have carried the compost
--  label. We try every one of those splits and count how many give a
--  difference at least as large as the one we observed. That fraction is
--  the p-value.

with Ada.Text_IO;            use Ada.Text_IO;
with Ada.Long_Float_Text_IO; use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Strings.Fixed;      use Ada.Strings.Fixed;
with Ada.Containers.Vectors;

procedure Main is
   package Integer_Vectors is new Ada.Containers.Vectors (Positive, Integer);
   use Integer_Vectors;

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

   function Total (V : Vector) return Integer is
      Sum : Integer := 0;
   begin
      for X of V loop
         Sum := Sum + X;
      end loop;
      return Sum;
   end Total;

   procedure Put_Value (Name : String; X : Long_Float) is
   begin
      Put (Name & " ");
      Put (X, Fore => 1, Aft => 6, Exp => 0);
      New_Line;
   end Put_Value;

   File             : File_Type;
   Control, Compost : Vector;
begin
   Open (File, In_File, Ada.Command_Line.Argument (1));
   declare
      Header  : constant String := Get_Line (File);
      Group_C : constant Positive := Column (Header, "group");
      Grams_C : constant Positive := Column (Header, "grams");
   begin
      while not End_Of_File (File) loop
         declare
            Line  : constant String := Get_Line (File);
            Grams : constant Integer := Integer'Value (Field (Line, Grams_C));
         begin
            if Field (Line, Group_C) = "control" then
               Control.Append (Grams);
            else
               Compost.Append (Grams);
            end if;
         end;
      end loop;
   end;
   Close (File);

   declare
      N         : constant Positive := Natural (Compost.Length);
      Plants    : constant Vector := Control & Compost;  --  & joins vectors
      All_Grams : constant Integer := Total (Plants);
      --  Both groups have N plants, so comparing totals is the same as
      --  comparing means, and Integer totals stay whole numbers: no
      --  floating-point near-ties.
      Observed   : constant Integer := Total (Compost) - Total (Control);
      Splits     : Natural := 0;
      As_Extreme : Natural := 0;

      --  Visit every way to choose Left more plants from position From
      --  onward. Each plant is either chosen (add it, and choose one fewer
      --  from the rest) or not (choose them all from the rest). A nested
      --  procedure can update Splits and As_Extreme in the block around it.
      procedure Choose (From : Positive; Left : Natural; Chosen : Integer) is
      begin
         if Left = 0 then
            declare
               Difference : constant Integer :=
                 Chosen - (All_Grams - Chosen);
            begin
               Splits := Splits + 1;
               --  Two-sided: a difference counts in either direction.
               if abs Difference >= abs Observed then
                  As_Extreme := As_Extreme + 1;
               end if;
            end;
         elsif Plants.Last_Index - From + 1 >= Left then
            Choose (From + 1, Left - 1, Chosen + Plants (From));
            Choose (From + 1, Left, Chosen);
         end if;
      end Choose;
   begin
      Choose (1, N, 0);
      Put_Line ("control_count" & Control.Length'Image);
      Put_Line ("compost_count" & N'Image);
      Put_Value ("control_mean",
                 Long_Float (Total (Control)) / Long_Float (Control.Length));
      Put_Value ("compost_mean", Long_Float (Total (Compost)) / Long_Float (N));
      Put_Value ("observed_difference", Long_Float (Observed) / Long_Float (N));
      Put_Line ("splits" & Splits'Image);
      Put_Line ("as_extreme" & As_Extreme'Image);
      Put_Value ("p_value", Long_Float (As_Extreme) / Long_Float (Splits));
   end;
end Main;
