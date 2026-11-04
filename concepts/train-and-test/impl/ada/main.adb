--  Train and test error for polynomials of degree 1 to 8, using only Ada's
--  standard library.
--
--  Each polynomial is fitted by least squares to the training drives only:
--  we build the normal equations and solve them by Gaussian elimination.
--  Then we measure its root-mean-square error on the training drives and on
--  the test drives it never saw.

with Ada.Text_IO;                use Ada.Text_IO;
with Ada.Long_Float_Text_IO;     use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;
with Ada.Numerics.Long_Real_Arrays;
use Ada.Numerics.Long_Real_Arrays;
with Ada.Containers.Vectors;

procedure Main is
   Max_Degree : constant := 8;

   --  Real_Vector and Real_Matrix come from Annex G of the standard, with
   --  "*" for matrix and vector products. Their index ranges are ours to
   --  choose, so coefficient vectors count from 0, like the powers.
   package Float_Vectors is new Ada.Containers.Vectors (Positive, Long_Float);

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

   --  A growable list of numbers as a Real_Vector, counting from 1.
   function To_Vector (List : Float_Vectors.Vector) return Real_Vector is
      Result : Real_Vector (1 .. Natural (List.Length));
   begin
      for I in Result'Range loop
         Result (I) := List (I);
      end loop;
      return Result;
   end To_Vector;

   --  The design matrix: row i is 1, z_i, z_i^2, ..., z_i^Degree.
   function Powers (Z : Real_Vector; Degree : Natural) return Real_Matrix is
      Result : Real_Matrix (Z'Range, 0 .. Degree);
   begin
      for I in Z'Range loop
         for J in 0 .. Degree loop
            Result (I, J) := Z (I) ** J;
         end loop;
      end loop;
      return Result;
   end Powers;

   --  Solve A x = B by Gaussian elimination with partial pivoting. A and B
   --  share the index range 0 .. N.
   function Gauss_Solve (A : Real_Matrix; B : Real_Vector) return Real_Vector
   is
      Last  : constant Integer := B'Last;
      --  The augmented matrix: A with B as an extra last column.
      M     : Real_Matrix (B'Range, B'First .. Last + 1);
      X     : Real_Vector (B'Range) := [others => 0.0];
      Pivot : Integer;
   begin
      for I in B'Range loop
         for J in B'Range loop
            M (I, J) := A (I, J);
         end loop;
         M (I, Last + 1) := B (I);
      end loop;
      for Col in B'Range loop
         --  Swap up the row with the largest entry in this column, which
         --  keeps the rounding error small. A 2-D array has no row objects
         --  to swap, so the two rows swap one entry at a time.
         Pivot := Col;
         for R in Col + 1 .. Last loop
            if abs M (R, Col) > abs M (Pivot, Col) then
               Pivot := R;
            end if;
         end loop;
         for C in M'Range (2) loop
            declare
               Held : constant Long_Float := M (Col, C);
            begin
               M (Col, C) := M (Pivot, C);
               M (Pivot, C) := Held;
            end;
         end loop;
         for R in Col + 1 .. Last loop
            declare
               Factor : constant Long_Float := M (R, Col) / M (Col, Col);
            begin
               for C in Col .. Last + 1 loop
                  M (R, C) := M (R, C) - Factor * M (Col, C);
               end loop;
            end;
         end loop;
      end loop;
      --  Back substitution, from the last unknown up.
      for R in reverse B'Range loop
         declare
            Known : Long_Float := 0.0;
         begin
            for C in R + 1 .. Last loop
               Known := Known + M (R, C) * X (C);
            end loop;
            X (R) := (M (R, Last + 1) - Known) / M (R, R);
         end;
      end loop;
      return X;
   end Gauss_Solve;

   --  Least squares: the coefficients c solve (Z^T Z) c = Z^T y.
   function Fit (Z, Y : Real_Vector; Degree : Natural) return Real_Vector is
      D : constant Real_Matrix := Powers (Z, Degree);
   begin
      return Gauss_Solve (Transpose (D) * D, Transpose (D) * Y);
   end Fit;

   function RMSE (Coefs, Z, Y : Real_Vector) return Long_Float is
      Errors : constant Real_Vector := Powers (Z, Coefs'Last) * Coefs - Y;
   begin
      --  Errors * Errors is the inner product, the sum of squared errors.
      return Sqrt ((Errors * Errors) / Long_Float (Y'Length));
   end RMSE;

   procedure Say (Name : String; Value : Long_Float) is
   begin
      Put (Name & " ");
      Put (Value, Fore => 1, Aft => 6, Exp => 0);   --  six decimals, no E
      New_Line;
   end Say;

   --  N'Image is " 1", so the slice drops the leading space.
   function Tag (N : Natural) return String is (N'Image (2 .. N'Image'Last));

   File : File_Type;
   Train_X, Train_Y, Test_X, Test_Y : Float_Vectors.Vector;
begin
   Open (File, In_File, Ada.Command_Line.Argument (1));
   declare
      Header   : constant String := Get_Line (File);
      Speed_C  : constant Positive := Column (Header, "speed");
      Litres_C : constant Positive := Column (Header, "litres");
      Split_C  : constant Positive := Column (Header, "split");
   begin
      while not End_Of_File (File) loop
         declare
            Line   : constant String := Get_Line (File);
            Speed  : constant Long_Float :=
              Long_Float'Value (Field (Line, Speed_C));
            Litres : constant Long_Float :=
              Long_Float'Value (Field (Line, Litres_C));
         begin
            if Field (Line, Split_C) = "train" then
               Train_X.Append (Speed);
               Train_Y.Append (Litres);
            else
               Test_X.Append (Speed);
               Test_Y.Append (Litres);
            end if;
         end;
      end loop;
   end;
   Close (File);

   declare
      Speeds : constant Real_Vector := To_Vector (Train_X);
      Low    : Long_Float := Speeds (Speeds'First);
      High   : Long_Float := Speeds (Speeds'First);
   begin
      for S of Speeds loop
         Low := Long_Float'Min (Low, S);
         High := Long_Float'Max (High, S);
      end loop;

      declare
         --  Map the training speeds onto -1 to 1. Raw speeds to the 16th
         --  power (the largest entry at degree 8) would swamp the small
         --  ones and make the equations hard to solve accurately.
         Mid  : constant Long_Float := (Low + High) / 2.0;
         Half : constant Long_Float := (High - Low) / 2.0;
         --  An aggregate with a for loop inside builds each vector of z.
         Train_Z : constant Real_Vector (Speeds'Range) :=
           [for I in Speeds'Range => (Speeds (I) - Mid) / Half];
         Test_Speeds : constant Real_Vector := To_Vector (Test_X);
         Test_Z  : constant Real_Vector (Test_Speeds'Range) :=
           [for I in Test_Speeds'Range => (Test_Speeds (I) - Mid) / Half];
         Y_Train : constant Real_Vector := To_Vector (Train_Y);
         Y_Test  : constant Real_Vector := To_Vector (Test_Y);
         Train_Errors, Test_Errors : Real_Vector (1 .. Max_Degree);
      begin
         for D in 1 .. Max_Degree loop
            declare
               Coefs : constant Real_Vector := Fit (Train_Z, Y_Train, D);
            begin
               Train_Errors (D) := RMSE (Coefs, Train_Z, Y_Train);
               Test_Errors (D) := RMSE (Coefs, Test_Z, Y_Test);
            end;
         end loop;
         Put_Line ("train_count" & Natural'Image (Speeds'Length));
         Put_Line ("test_count" & Natural'Image (Test_Speeds'Length));
         for D in 1 .. Max_Degree loop
            Say ("train_rmse_d" & Tag (D), Train_Errors (D));
         end loop;
         for D in 1 .. Max_Degree loop
            Say ("test_rmse_d" & Tag (D), Test_Errors (D));
         end loop;
      end;
   end;
end Main;
