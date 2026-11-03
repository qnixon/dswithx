--  Logistic regression by gradient descent, using only Ada's standard
--  library.
--
--  Predicts whether a student passed from study hours and sleep. Each
--  feature is rescaled with the training rows' mean and standard deviation,
--  then the weights start at zero and take Steps fixed steps of batch
--  gradient descent on the average log-loss.

with Ada.Text_IO;                use Ada.Text_IO;
with Ada.Long_Float_Text_IO;     use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Strings.Fixed;          use Ada.Strings.Fixed;
with Ada.Numerics.Long_Elementary_Functions;
use Ada.Numerics.Long_Elementary_Functions;
with Ada.Containers.Vectors;

procedure Main is
   Learning_Rate : constant := 0.5;
   Steps         : constant := 1000;

   --  Inputs (0) is always 1, so weight 0 acts as the intercept; 1 and 2
   --  are hours and sleep.
   type Inputs is array (0 .. 2) of Long_Float;
   type Example is record
      X : Inputs;
      Y : Natural;   --  1 if the student passed, else 0
   end record;
   package Example_Vectors is new Ada.Containers.Vectors (Positive, Example);
   use Example_Vectors;

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

   --  The number (counting from 1) of the column called Name.
   function Column (Header, Name : String) return Positive is
   begin
      for C in 1 .. Ada.Strings.Fixed.Count (Header, ",") + 1 loop
         if Field (Header, C) = Name then
            return C;
         end if;
      end loop;
      raise Constraint_Error with "column not found: " & Name;
   end Column;

   --  Read the CSV into training and test rows, sorted by the "split" column.
   procedure Read_Rows (Path : String; Train, Test : out Vector) is
      File : File_Type;
   begin
      Open (File, In_File, Path);
      declare
         Header : constant String   := Get_Line (File);
         Hours  : constant Positive := Column (Header, "hours");
         Sleep  : constant Positive := Column (Header, "sleep");
         Passed : constant Positive := Column (Header, "passed");
         Split  : constant Positive := Column (Header, "split");
      begin
         while not End_Of_File (File) loop
            declare
               Line : constant String  := Get_Line (File);
               Row  : constant Example :=
                 (X => [1.0,
                        Long_Float'Value (Field (Line, Hours)),
                        Long_Float'Value (Field (Line, Sleep))],
                  Y => Natural'Value (Field (Line, Passed)));
            begin
               if Field (Line, Split) = "train" then
                  Train.Append (Row);
               else
                  Test.Append (Row);
               end if;
            end;
         end loop;
      end;
      Close (File);
   end Read_Rows;

   --  The probability of passing: the sigmoid of the weighted sum of inputs.
   function Predict (W, X : Inputs) return Long_Float is
      Z : Long_Float := 0.0;
   begin
      for J in Inputs'Range loop
         Z := Z + W (J) * X (J);
      end loop;
      return 1.0 / (1.0 + Exp (-Z));
   end Predict;

   procedure Say (Name : String; Value : Long_Float) is
   begin
      Put (Name & " ");
      Put (Value, Fore => 1, Aft => 6, Exp => 0);   --  six decimals, no E
      New_Line;
   end Say;

   Train, Test : Vector;
   W           : Inputs := [others => 0.0];
   Correct     : Natural := 0;
   Loss        : Long_Float := 0.0;
begin
   Read_Rows (Ada.Command_Line.Argument (1), Train, Test);

   declare
      N : constant Long_Float := Long_Float (Train.Length);
   begin
      --  Scale each feature to mean 0 and (sample) standard deviation 1,
      --  using the training rows only, then apply the same shift to the
      --  test rows. Input 0 holds the ones, so the features are 1 and 2.
      for J in 1 .. 2 loop
         declare
            Total, Squares : Long_Float := 0.0;
            Mean, Sd       : Long_Float;
         begin
            for R of Train loop
               Total := Total + R.X (J);
            end loop;
            Mean := Total / N;
            for R of Train loop
               Squares := Squares + (R.X (J) - Mean) ** 2;
            end loop;
            Sd := Sqrt (Squares / (N - 1.0));
            --  "for R of" over a variable vector lets us change R in place.
            for R of Train loop
               R.X (J) := (R.X (J) - Mean) / Sd;
            end loop;
            for R of Test loop
               R.X (J) := (R.X (J) - Mean) / Sd;
            end loop;
         end;
      end loop;

      for Step in 1 .. Steps loop
         --  Gradient of the average log-loss: the mean of (p - y) times each
         --  input. It is summed over every student before any weight moves.
         declare
            Gradient : Inputs := [others => 0.0];
            Error    : Long_Float;
         begin
            for R of Train loop
               Error := Predict (W, R.X) - Long_Float (R.Y);
               for J in Inputs'Range loop
                  Gradient (J) := Gradient (J) + Error * R.X (J);
               end loop;
            end loop;
            for J in Inputs'Range loop
               W (J) := W (J) - Learning_Rate * Gradient (J) / N;
            end loop;
         end;
      end loop;

      for R of Train loop
         Loss := Loss - (if R.Y = 1 then Log (Predict (W, R.X))
                         else Log (1.0 - Predict (W, R.X)));
      end loop;
      Loss := Loss / N;
   end;

   for R of Test loop
      --  Boolean'Pos turns False and True into 0 and 1.
      if Boolean'Pos (Predict (W, R.X) >= 0.5) = R.Y then
         Correct := Correct + 1;
      end if;
   end loop;

   Put_Line ("train_count" & Train.Length'Image);
   Put_Line ("test_count" & Test.Length'Image);
   Say ("intercept", W (0));
   Say ("weight_hours", W (1));
   Say ("weight_sleep", W (2));
   Say ("log_loss", Loss);
   Put_Line ("correct" & Correct'Image);
   Say ("accuracy", Long_Float (Correct) / Long_Float (Test.Length));
end Main;
