--  Descriptive statistics on one CSV column, using only Ada's standard
--  library.
--
--  Ada has no mean, median, or variance, so each is written out. Types are
--  strict: an Integer count must be converted with Long_Float (N) before it
--  can divide a Long_Float total.

with Ada.Text_IO;                use Ada.Text_IO;
with Ada.Long_Float_Text_IO;     use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;
with Ada.Containers.Vectors;
with Ada.Containers.Generic_Array_Sort;

procedure Main is
   --  A growable list of numbers, indexed from 1.
   package Float_Vectors is new Ada.Containers.Vectors (Positive, Long_Float);

   type Float_Array is array (Positive range <>) of Long_Float;
   procedure Sort is new Ada.Containers.Generic_Array_Sort
     (Positive, Long_Float, Float_Array);

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

   function Read_Column (Path, Name : String) return Float_Array is
      File   : File_Type;
      Values : Float_Vectors.Vector;
      Col    : Natural := 0;
   begin
      Open (File, In_File, Path);
      declare
         Header : constant String := Get_Line (File);
      begin
         for C in 1 .. Ada.Strings.Fixed.Count (Header, ",") + 1 loop
            if Field (Header, C) = Name then
               Col := C;
            end if;
         end loop;
      end;
      if Col = 0 then
         raise Constraint_Error with "column not found: " & Name;
      end if;
      while not End_Of_File (File) loop
         Values.Append (Long_Float'Value (Field (Get_Line (File), Col)));
      end loop;
      Close (File);
      --  Copy the vector into a fixed-size array, which Sort works on.
      return Result : Float_Array (1 .. Natural (Values.Length)) do
         for I in Result'Range loop
            Result (I) := Values (I);
         end loop;
      end return;
   end Read_Column;

   procedure Say (Name : String; Value : Long_Float) is
   begin
      Put (Name & " ");
      Put (Value, Fore => 1, Aft => 6, Exp => 0);   --  six decimals, no E
      New_Line;
   end Say;

   Values : Float_Array := Read_Column (Ada.Command_Line.Argument (1), "minutes");
   N      : constant Positive := Values'Length;
   Total, Sum_Sq, Mean, Median, Variance : Long_Float := 0.0;
begin
   Sort (Values);

   for V of Values loop
      Total := Total + V;
   end loop;
   Mean := Total / Long_Float (N);

   --  N / 2 on two Integers rounds toward zero.
   if N mod 2 = 1 then
      Median := Values (N / 2 + 1);
   else
      Median := (Values (N / 2) + Values (N / 2 + 1)) / 2.0;
   end if;

   --  Sample variance divides by n - 1, not n (Bessel's correction).
   for V of Values loop
      Sum_Sq := Sum_Sq + (V - Mean) ** 2;
   end loop;
   Variance := Sum_Sq / Long_Float (N - 1);

   Put_Line ("count" & Integer'Image (N));
   Say ("sum", Total);
   Say ("mean", Mean);
   Say ("median", Median);
   Say ("min", Values (1));
   Say ("max", Values (N));
   Say ("range", Values (N) - Values (1));
   Say ("variance", Variance);
   Say ("std_dev", Sqrt (Variance));
end Main;
