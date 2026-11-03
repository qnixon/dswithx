--  Simple linear regression by least squares, using only Ada's standard
--  library.
--
--  Fits score = intercept + slope * hours. Ada has no mean, sum, or
--  regression function, so every total is a loop over two arrays.

with Ada.Text_IO;                use Ada.Text_IO;
with Ada.Long_Float_Text_IO;     use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;
with Ada.Containers.Vectors;

procedure Main is
   --  A growable list of numbers, indexed from 1.
   package Float_Vectors is new Ada.Containers.Vectors (Positive, Long_Float);

   type Float_Array is array (Positive range <>) of Long_Float;

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
      --  Copy the vector into a fixed-size array.
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

   --  Each column is read on its own; row I of the file is Xs (I) and Ys (I).
   Xs : constant Float_Array := Read_Column (Ada.Command_Line.Argument (1), "hours");
   Ys : constant Float_Array := Read_Column (Ada.Command_Line.Argument (1), "score");
   N  : constant Positive := Xs'Length;
   Sum_X, Sum_Y, Sxx, Syy, Sxy : Long_Float := 0.0;
begin
   if Ys'Length /= N then   --  /= is "not equal"
      raise Constraint_Error with "columns differ in length";
   end if;

   --  First pass: the means.
   for I in Xs'Range loop
      Sum_X := Sum_X + Xs (I);
      Sum_Y := Sum_Y + Ys (I);
   end loop;

   declare
      Mean_X : constant Long_Float := Sum_X / Long_Float (N);
      Mean_Y : constant Long_Float := Sum_Y / Long_Float (N);
   begin
      --  Second pass: sums of squared deviations and of cross-products.
      for I in Xs'Range loop
         declare
            Dx : constant Long_Float := Xs (I) - Mean_X;
            Dy : constant Long_Float := Ys (I) - Mean_Y;
         begin
            Sxx := Sxx + Dx * Dx;
            Syy := Syy + Dy * Dy;
            Sxy := Sxy + Dx * Dy;
         end;
      end loop;

      declare
         Slope     : constant Long_Float := Sxy / Sxx;
         Intercept : constant Long_Float := Mean_Y - Slope * Mean_X;
         R         : constant Long_Float := Sxy / Sqrt (Sxx * Syy);
      begin
         Put_Line ("count" & Integer'Image (N));
         Say ("slope", Slope);
         Say ("intercept", Intercept);
         Say ("r", R);
         Say ("r_squared", R * R);
      end;
   end;
end Main;
