--  Evaluation metrics for a binary classifier, using only Ada's standard
--  library.
--
--  Reads each part's true label and the model's score, then reports the
--  confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
--  the accuracy of never flagging anything, and the area under the ROC
--  curve.

with Ada.Text_IO;            use Ada.Text_IO;
with Ada.Long_Float_Text_IO; use Ada.Long_Float_Text_IO;
with Ada.Command_Line;
with Ada.Strings.Fixed;      use Ada.Strings.Fixed;
with Ada.Containers.Vectors;

procedure Main is
   type Part is record
      Defective : Boolean;
      Score     : Long_Float;
   end record;

   package Part_Vectors is new Ada.Containers.Vectors (Positive, Part);
   use Part_Vectors;

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

   --  Ada never mixes Integer and Long_Float: each count is converted
   --  before the division.
   function Ratio (A, B : Natural) return Long_Float is
     (Long_Float (A) / Long_Float (B));

   procedure Put_Value (Name : String; X : Long_Float) is
   begin
      Put (Name & " ");
      Put (X, Fore => 1, Aft => 6, Exp => 0);
      New_Line;
   end Put_Value;

   --  'Image puts a space before a non-negative number, which serves as
   --  the space between the name and the count.
   procedure Put_Count (Name : String; X : Natural) is
   begin
      Put_Line (Name & X'Image);
   end Put_Count;

   --  The confusion matrix and the metrics built from it, at one threshold.
   procedure Report (Parts : Vector; Suffix : String; Threshold : Long_Float)
   is
      TP, FP, FN, TN : Natural := 0;
   begin
      for P of Parts loop
         --  A part is flagged when its score reaches the threshold.
         if P.Score >= Threshold then
            if P.Defective then
               TP := TP + 1;
            else
               FP := FP + 1;
            end if;
         elsif P.Defective then
            FN := FN + 1;
         else
            TN := TN + 1;
         end if;
      end loop;

      declare
         Accuracy  : constant Long_Float :=
           Ratio (TP + TN, Natural (Parts.Length));
         --  Of the flagged parts, how many are defective.
         Precision : constant Long_Float := Ratio (TP, TP + FP);
         --  Of the defective parts, how many are flagged.
         Recall    : constant Long_Float := Ratio (TP, TP + FN);
         F1        : constant Long_Float :=
           2.0 * Precision * Recall / (Precision + Recall);
      begin
         Put_Count ("tp_at_" & Suffix, TP);
         Put_Count ("fp_at_" & Suffix, FP);
         Put_Count ("fn_at_" & Suffix, FN);
         Put_Count ("tn_at_" & Suffix, TN);
         Put_Value ("accuracy_at_" & Suffix, Accuracy);
         Put_Value ("precision_at_" & Suffix, Precision);
         Put_Value ("recall_at_" & Suffix, Recall);
         Put_Value ("f1_at_" & Suffix, F1);
      end;
   end Report;

   --  The chance that a random defective part outscores a random good one.
   --  Compare every pair, scoring 2 for a win and 1 for a tie, so the count
   --  stays a whole number until the final division.
   function AUC (Parts : Vector) return Long_Float is
      Points, Defective, Good : Natural := 0;
   begin
      for D of Parts loop
         if D.Defective then
            Defective := Defective + 1;
            for G of Parts loop
               if not G.Defective then
                  if D.Score > G.Score then
                     Points := Points + 2;
                  elsif D.Score = G.Score then
                     Points := Points + 1;
                  end if;
               end if;
            end loop;
         else
            Good := Good + 1;
         end if;
      end loop;
      return Ratio (Points, 2 * Defective * Good);
   end AUC;

   File  : File_Type;
   Parts : Vector;
begin
   Open (File, In_File, Ada.Command_Line.Argument (1));
   declare
      Header      : constant String := Get_Line (File);
      Defective_C : constant Positive := Column (Header, "defective");
      Score_C     : constant Positive := Column (Header, "score");
   begin
      while not End_Of_File (File) loop
         declare
            Line : constant String := Get_Line (File);
         begin
            --  Part'(...) names the type of the aggregate. A Vector can
            --  also be written as an aggregate in Ada 2022, so without it
            --  the call to Append would be ambiguous.
            Parts.Append
              (Part'(Defective => Field (Line, Defective_C) = "1",
                     Score     => Long_Float'Value (Field (Line, Score_C))));
         end;
      end loop;
   end;
   Close (File);

   declare
      N         : constant Natural := Natural (Parts.Length);
      Defective : Natural := 0;
   begin
      for P of Parts loop
         if P.Defective then
            Defective := Defective + 1;
         end if;
      end loop;
      Put_Count ("parts", N);
      Put_Count ("defective", Defective);
      --  Never flagging anything is right about every good part.
      Put_Value ("baseline_accuracy", Ratio (N - Defective, N));
      Report (Parts, "50", 0.5);
      Report (Parts, "30", 0.3);
      Put_Value ("auc", AUC (Parts));
   end;
end Main;
