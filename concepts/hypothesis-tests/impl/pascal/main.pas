{ Exact two-sided permutation test for a difference in means, using only
  Free Pascal's run-time library.

  If compost made no difference, the "compost" and "control" labels are
  arbitrary, and any N of the plants could have carried the compost label.
  We try every one of those splits and count how many give a difference at
  least as large as the one we observed. That fraction is the p-value. }
program HypothesisTest;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils;

type
  TIntArray = array of Integer;

var
  Control, Compost, Plants: TIntArray;
  N, Total, Observed, Splits, AsExtreme: Integer;

// Read the grams of each group into Control and Compost.
procedure ReadPlants(const Path: String);
var
  F: TextFile;
  Line: String;
  Fields: TStringArray;
  GroupCol, GramsCol, I: Integer;
begin
  AssignFile(F, Path);
  Reset(F);
  ReadLn(F, Line);
  Fields := Line.Split(',');
  GroupCol := -1;
  GramsCol := -1;
  for I := 0 to High(Fields) do
    if Fields[I] = 'group' then GroupCol := I
    else if Fields[I] = 'grams' then GramsCol := I;
  if (GroupCol < 0) or (GramsCol < 0) then
    raise Exception.Create('column not found');
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Fields := Line.Split(',');
    // Insert(Value, Array, Length(Array)) appends.
    if Fields[GroupCol] = 'control' then
      Insert(StrToInt(Fields[GramsCol]), Control, Length(Control))
    else
      Insert(StrToInt(Fields[GramsCol]), Compost, Length(Compost));
  end;
  CloseFile(F);
end;

function Sum(const Values: TIntArray): Integer;
var
  V: Integer;
begin
  Result := 0;
  for V in Values do
    Result := Result + V;
end;

// Walk the plants from position Next on, choosing Left more of them to carry
// the compost label. Chosen is the total of those picked so far. Each call
// either takes plant Next or skips it, so every choice is reached once.
procedure Choose(Next, Left, Chosen: Integer);
begin
  if Left = 0 then
  begin
    Inc(Splits);
    // Two-sided: Abs counts a difference in either direction.
    if Abs(Chosen - (Total - Chosen)) >= Abs(Observed) then
      Inc(AsExtreme);
    Exit;
  end;
  if Length(Plants) - Next < Left then
    Exit;  // too few plants left to finish this choice
  Choose(Next + 1, Left - 1, Chosen + Plants[Next]);
  Choose(Next + 1, Left, Chosen);
end;

begin
  Control := nil;
  Compost := nil;
  ReadPlants(ParamStr(1));
  N := Length(Compost);
  Plants := Concat(Control, Compost);
  Total := Sum(Plants);

  // Both groups have N plants, so comparing totals is the same as comparing
  // means, and totals stay whole numbers: no floating-point near-ties.
  Observed := Sum(Compost) - Sum(Control);

  Splits := 0;
  AsExtreme := 0;
  Choose(0, N, 0);

  WriteLn('control_count ', Length(Control));
  WriteLn('compost_count ', N);
  WriteLn('control_mean ', Sum(Control) / Length(Control):0:6);
  WriteLn('compost_mean ', Sum(Compost) / N:0:6);
  WriteLn('observed_difference ', Observed / N:0:6);
  WriteLn('splits ', Splits);
  WriteLn('as_extreme ', AsExtreme);
  WriteLn('p_value ', AsExtreme / Splits:0:6);
end.
