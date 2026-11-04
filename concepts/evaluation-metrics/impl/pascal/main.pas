{ Evaluation metrics for a binary classifier, using only Free Pascal's
  run-time library.

  Reads each part's true label and the model's score, then reports the
  confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
  the accuracy of never flagging anything, and the area under the ROC
  curve. }
program EvaluationMetrics;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils;

type
  TPart = record
    Defective: Boolean;
    Score: Double;
  end;
  TPartArray = array of TPart;

var
  Parts: TPartArray;
  Part: TPart;
  Defective: Integer;

// Read every part's label and score.
function ReadParts(const Path: String): TPartArray;
var
  F: TextFile;
  Line: String;
  Fields: TStringArray;
  DefectiveCol, ScoreCol, I: Integer;
  P: TPart;
begin
  Result := nil;
  AssignFile(F, Path);
  Reset(F);
  ReadLn(F, Line);
  Fields := Line.Split(',');
  DefectiveCol := -1;
  ScoreCol := -1;
  for I := 0 to High(Fields) do
    if Fields[I] = 'defective' then DefectiveCol := I
    else if Fields[I] = 'score' then ScoreCol := I;
  if (DefectiveCol < 0) or (ScoreCol < 0) then
    raise Exception.Create('column not found');
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Fields := Line.Split(',');
    P.Defective := Fields[DefectiveCol] = '1';
    // StrToFloat reads "0.174"; equal strings give equal Doubles.
    P.Score := StrToFloat(Fields[ScoreCol]);
    // Insert(Value, Array, Length(Array)) appends.
    Insert(P, Result, Length(Result));
  end;
  CloseFile(F);
end;

// Threshold is a Double, so the literal it's given is rounded the same way
// as the scores before they're compared.
procedure Report(const Suffix: String; Threshold: Double);
var
  TP, FP, FN, TN: Integer;
  Flagged: Boolean;
  Accuracy, Precision, Recall, F1: Double;
begin
  TP := 0; FP := 0; FN := 0; TN := 0;
  for Part in Parts do
  begin
    // A part is flagged when its score reaches the threshold.
    Flagged := Part.Score >= Threshold;
    if Flagged and Part.Defective then Inc(TP)
    else if Flagged then Inc(FP)
    else if Part.Defective then Inc(FN)
    else Inc(TN);
  end;

  // / always divides as a decimal; div is whole-number division.
  Accuracy := (TP + TN) / Length(Parts);
  Precision := TP / (TP + FP);  // of the flagged parts, how many are defective
  Recall := TP / (TP + FN);     // of the defective parts, how many are flagged
  F1 := 2 * Precision * Recall / (Precision + Recall);

  WriteLn('tp_at_', Suffix, ' ', TP);
  WriteLn('fp_at_', Suffix, ' ', FP);
  WriteLn('fn_at_', Suffix, ' ', FN);
  WriteLn('tn_at_', Suffix, ' ', TN);
  WriteLn('accuracy_at_', Suffix, ' ', Accuracy:0:6);
  WriteLn('precision_at_', Suffix, ' ', Precision:0:6);
  WriteLn('recall_at_', Suffix, ' ', Recall:0:6);
  WriteLn('f1_at_', Suffix, ' ', F1:0:6);
end;

// The chance that a random defective part outscores a random good one.
// Compare every pair, scoring 2 for a win and 1 for a tie, so the count
// stays a whole number until the final division.
function AUC: Double;
var
  D, G: TPart;
  Points: Integer;
begin
  Points := 0;
  for D in Parts do
    if D.Defective then
      for G in Parts do
        if not G.Defective then
          if D.Score > G.Score then Inc(Points, 2)
          else if D.Score = G.Score then Inc(Points);
  Result := Points / (2 * Defective * (Length(Parts) - Defective));
end;

begin
  Parts := ReadParts(ParamStr(1));
  Defective := 0;
  for Part in Parts do
    if Part.Defective then Inc(Defective);

  WriteLn('parts ', Length(Parts));
  WriteLn('defective ', Defective);
  // Never flagging anything is right about every good part.
  WriteLn('baseline_accuracy ', (Length(Parts) - Defective) / Length(Parts):0:6);
  Report('50', 0.5);
  Report('30', 0.3);
  WriteLn('auc ', AUC:0:6);
end.
