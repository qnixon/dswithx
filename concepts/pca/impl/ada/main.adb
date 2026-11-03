--  Principal component analysis by power iteration, using only Ada's
--  standard library.
--
--  Standardizes the four scores, builds their correlation matrix, and finds
--  the top two eigenvectors (the principal components): power iteration
--  finds the first, then deflation removes it from the matrix so the same
--  steps find the second.

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
   K     : constant := 4;
   Steps : constant := 1000;
   Subjects : constant array (1 .. K) of String (1 .. 7) :=
     ["math   ", "physics", "reading", "writing"];   --  padded to one length

   --  Real_Vector and Real_Matrix come from Annex G of the standard, with
   --  "*" for matrix and vector products and "abs" for a vector's length.
   subtype Row is Real_Vector (1 .. K);
   package Row_Vectors is new Ada.Containers.Vectors (Positive, Row);

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

   --  Read the four subject columns into an n by k matrix.
   function Read_Scores (Path : String) return Real_Matrix is
      File : File_Type;
      Rows : Row_Vectors.Vector;
      Cols : array (1 .. K) of Natural := [others => 0];
   begin
      Open (File, In_File, Path);
      declare
         Header : constant String := Get_Line (File);
      begin
         for C in 1 .. Ada.Strings.Fixed.Count (Header, ",") + 1 loop
            for J in 1 .. K loop
               if Field (Header, C) = Trim (Subjects (J), Ada.Strings.Right)
               then
                  Cols (J) := C;
               end if;
            end loop;
         end loop;
      end;
      while not End_Of_File (File) loop
         declare
            Line   : constant String := Get_Line (File);
            Scores : Row;
         begin
            for J in 1 .. K loop
               Scores (J) := Long_Float'Value (Field (Line, Cols (J)));
            end loop;
            Rows.Append (Scores);
         end;
      end loop;
      Close (File);
      return Result : Real_Matrix (1 .. Natural (Rows.Length), 1 .. K) do
         for I in Result'Range (1) loop
            for J in 1 .. K loop
               Result (I, J) := Rows (I) (J);
            end loop;
         end loop;
      end return;
   end Read_Scores;

   --  Power iteration: multiply by the matrix and rescale, Steps times.
   procedure Top_Eigenvector (M : Real_Matrix; Value : out Long_Float;
                              V : out Row) is
   begin
      V := [1.0, 0.0, 0.0, 0.0];
      for Step in 1 .. Steps loop
         V := M * V;
         V := V / abs V;
      end loop;
      --  An eigenvector can point either way; make its first entry positive.
      if V (1) < 0.0 then
         V := -V;
      end if;
      Value := V * (M * V);   --  the Rayleigh quotient, an inner product
   end Top_Eigenvector;

   procedure Say (Name : String; Value : Long_Float) is
   begin
      Put (Name & " ");
      Put (Value, Fore => 1, Aft => 6, Exp => 0);   --  six decimals, no E
      New_Line;
   end Say;

   procedure Report (C : Positive; Value : Long_Float; PC : Row) is
      --  C'Image is " 1", so the slice drops the leading space.
      Tag : constant String := C'Image (2 .. C'Image'Last);
   begin
      Say ("eigenvalue_" & Tag, Value);
      --  Standardized columns each have variance 1, so the total is k.
      Say ("explained_" & Tag, Value / Long_Float (K));
      for J in 1 .. K loop
         Say ("pc" & Tag & "_" & Trim (Subjects (J), Ada.Strings.Right),
              PC (J));
      end loop;
   end Report;

   Z : Real_Matrix := Read_Scores (Ada.Command_Line.Argument (1));
   N : constant Positive := Z'Length (1);
   Value_1, Value_2 : Long_Float;
   PC_1, PC_2       : Row;
begin
   --  Standardize each column to mean 0 and (sample) standard deviation 1.
   for J in 1 .. K loop
      declare
         Total, Squares : Long_Float := 0.0;
         Mean, Sd       : Long_Float;
      begin
         for I in 1 .. N loop
            Total := Total + Z (I, J);
         end loop;
         Mean := Total / Long_Float (N);
         for I in 1 .. N loop
            Squares := Squares + (Z (I, J) - Mean) ** 2;
         end loop;
         Sd := Sqrt (Squares / Long_Float (N - 1));
         for I in 1 .. N loop
            Z (I, J) := (Z (I, J) - Mean) / Sd;
         end loop;
      end;
   end loop;

   declare
      --  The correlation matrix: the covariance of the standardized columns.
      --  Transpose (Z) is k by n, so the product is k by k.
      Corr : constant Real_Matrix := Transpose (Z) * Z / Long_Float (N - 1);
   begin
      Top_Eigenvector (Corr, Value_1, PC_1);
      --  Deflation: subtract the first component's share, leaving the rest.
      --  "*" of two vectors gives a matrix (the outer product) when a matrix
      --  is wanted, and a number (the inner product) when a number is.
      Top_Eigenvector (Corr - Value_1 * (PC_1 * PC_1), Value_2, PC_2);
   end;

   Put_Line ("count" & N'Image);
   Report (1, Value_1, PC_1);
   Report (2, Value_2, PC_2);
   declare
      First : Row;   --  the first student's standardized scores
   begin
      for J in 1 .. K loop
         First (J) := Z (1, J);
      end loop;
      Say ("student_1_pc1", First * PC_1);
      Say ("student_1_pc2", First * PC_2);
   end;
end Main;
