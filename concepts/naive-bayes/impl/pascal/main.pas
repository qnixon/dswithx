{ Categorical naive Bayes with add-one (Laplace) smoothing, using only Free
  Pascal's run-time library.

  Learns P(label) and P(feature value | label) by counting training rows,
  then labels each test row with the label that has the highest
  log-probability. Sorting the labels uses TArrayHelper from
  Generics.Collections. }
program NaiveBayes;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils, Generics.Collections;

const
  NFeatures = 3;
  Features: array[0..NFeatures - 1] of String =
    ('has_link', 'mentions_money', 'known_sender');

type
  // One email: its three feature values, its label, and its split.
  TRow = record
    Values: array[0..NFeatures - 1] of String;
    Label_, Split: String;  // "label" is a reserved word, hence the underscore
  end;
  TRowArray = array of TRow;
  TLabelArray = array of String;

function ReadRows(const Path: String): TRowArray;
var
  F: TextFile;
  Line: String;
  Fields: TStringArray;
  Cols: array[0..NFeatures - 1] of Integer;
  LabelCol, SplitCol, I, C: Integer;
begin
  Result := nil;
  AssignFile(F, Path);
  Reset(F);
  ReadLn(F, Line);
  Fields := Line.Split(',');
  for C := 0 to NFeatures - 1 do
    Cols[C] := -1;
  LabelCol := -1;
  SplitCol := -1;
  for I := 0 to High(Fields) do
  begin
    for C := 0 to NFeatures - 1 do
      if Fields[I] = Features[C] then Cols[C] := I;
    if Fields[I] = 'label' then LabelCol := I;
    if Fields[I] = 'split' then SplitCol := I;
  end;
  for C := 0 to NFeatures - 1 do
    if Cols[C] < 0 then
      raise Exception.Create('column not found: ' + Features[C]);
  if (LabelCol < 0) or (SplitCol < 0) then
    raise Exception.Create('no label or split column');
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    if Line = '' then
      Continue;
    Fields := Line.Split(',');
    SetLength(Result, Length(Result) + 1);  // grow by one
    for C := 0 to NFeatures - 1 do
      Result[High(Result)].Values[C] := Fields[Cols[C]];
    Result[High(Result)].Label_ := Fields[LabelCol];
    Result[High(Result)].Split := Fields[SplitCol];
  end;
  CloseFile(F);
end;

var
  Train: TRowArray;
  Labels: TLabelArray;
  DistinctValues: array[0..NFeatures - 1] of Integer;

{ Training rows with this label and, if Feature >= 0, this value of it.
  There is no dictionary of counts: each call recounts. }
function CountRows(const Lbl: String; Feature: Integer; const Value: String): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Train) do
    if (Train[I].Label_ = Lbl) and
       ((Feature < 0) or (Train[I].Values[Feature] = Value)) then
      Inc(Result);
end;

function LogScore(const Row: TRow; const Lbl: String): Double;
var
  LabelCount, Count, C: Integer;
begin
  LabelCount := CountRows(Lbl, -1, '');
  // Logs turn the product of probabilities into a sum, avoiding underflow.
  Result := Ln(LabelCount / Length(Train));
  for C := 0 to NFeatures - 1 do
  begin
    // Add-one smoothing: an unseen value never gets probability zero.
    Count := CountRows(Lbl, C, Row.Values[C]) + 1;
    Result := Result + Ln(Count / (LabelCount + DistinctValues[C]));
  end;
end;

{ Labels are tried in sorted (character-code) order, and only a strictly higher score
  replaces the best, so an exact tie goes to the first. }
function Classify(const Row: TRow): String;
var
  Best, Score: Double;
  L: Integer;
begin
  Result := Labels[0];
  Best := LogScore(Row, Result);
  for L := 1 to High(Labels) do
  begin
    Score := LogScore(Row, Labels[L]);
    if Score > Best then
    begin
      Result := Labels[L];
      Best := Score;
    end;
  end;
end;

{ True if any of the first Before training rows has this label (Feature < 0)
  or this value of Feature. }
function SeenEarlier(Before, Feature: Integer; const Text: String): Boolean;
var
  E: Integer;
begin
  Result := False;
  for E := 0 to Before - 1 do
    if ((Feature < 0) and (Train[E].Label_ = Text)) or
       ((Feature >= 0) and (Train[E].Values[Feature] = Text)) then
      Exit(True);
end;

var
  Rows: TRowArray;
  I, C, TestCount, Correct: Integer;
begin
  Rows := ReadRows(ParamStr(1));

  // Records are values, so Train holds copies of the training rows.
  Train := nil;
  for I := 0 to High(Rows) do
    if Rows[I].Split = 'train' then
    begin
      SetLength(Train, Length(Train) + 1);
      Train[High(Train)] := Rows[I];
    end;
  if Length(Train) = 0 then
    raise Exception.Create('no training rows');

  // A label or value is new if no earlier training row has it.
  Labels := nil;
  for C := 0 to NFeatures - 1 do
    DistinctValues[C] := 0;
  for I := 0 to High(Train) do
  begin
    if not SeenEarlier(I, -1, Train[I].Label_) then
    begin
      SetLength(Labels, Length(Labels) + 1);
      Labels[High(Labels)] := Train[I].Label_;
    end;
    for C := 0 to NFeatures - 1 do
      if not SeenEarlier(I, C, Train[I].Values[C]) then
        Inc(DistinctValues[C]);
  end;
  specialize TArrayHelper<String>.Sort(Labels);

  TestCount := 0;
  Correct := 0;
  for I := 0 to High(Rows) do
    if Rows[I].Split = 'test' then
    begin
      Inc(TestCount);
      if Classify(Rows[I]) = Rows[I].Label_ then
        Inc(Correct);
    end;

  WriteLn('train_count ', Length(Train));
  WriteLn('test_count ', TestCount);
  WriteLn('correct ', Correct);
  WriteLn('accuracy ', Correct / TestCount:0:6);  // width 0, six decimals
end.
