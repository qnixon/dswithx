{ Descriptive statistics on one CSV column, using only Free Pascal's
  run-time library.

  The Math unit has Mean, Variance, and StdDev, but they are left out here,
  so every statistic is written out. Sorting uses TArrayHelper from
  Generics.Collections. }
program DescriptiveStatistics;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils, Generics.Collections;

type
  TDoubleArray = array of Double;

function ReadColumn(const Path, Name: String): TDoubleArray;
var
  F: TextFile;
  Line: String;
  Fields: TStringArray;
  Col, I: Integer;
begin
  Result := nil;
  AssignFile(F, Path);
  Reset(F);
  ReadLn(F, Line);
  Fields := Line.Split(',');
  Col := -1;
  for I := 0 to High(Fields) do
    if Fields[I] = Name then
      Col := I;
  if Col < 0 then
    raise Exception.Create('column not found: ' + Name);
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Fields := Line.Split(',');
    SetLength(Result, Length(Result) + 1);  // grow by one
    Result[High(Result)] := StrToFloat(Fields[Col]);
  end;
  CloseFile(F);
end;

function Median(const Sorted: TDoubleArray): Double;
var
  N: Integer;
begin
  N := Length(Sorted);
  if Odd(N) then
    Result := Sorted[N div 2]
  else
    Result := (Sorted[N div 2 - 1] + Sorted[N div 2]) / 2;
end;

procedure Say(const Name: String; Value: Double);
begin
  WriteLn(Name, ' ', Value:0:6);  // width 0, six decimals
end;

var
  Values: TDoubleArray;
  N, I: Integer;
  Total, Mean, SumSq, Variance: Double;
begin
  Values := ReadColumn(ParamStr(1), 'minutes');
  specialize TArrayHelper<Double>.Sort(Values);

  N := Length(Values);
  Total := 0;
  for I := 0 to N - 1 do
    Total := Total + Values[I];
  Mean := Total / N;  // / always gives a real; div is for integers

  // Sample variance divides by n - 1, not n (Bessel's correction).
  SumSq := 0;
  for I := 0 to N - 1 do
    SumSq := SumSq + Sqr(Values[I] - Mean);
  Variance := SumSq / (N - 1);

  WriteLn('count ', N);
  Say('sum', Total);
  Say('mean', Mean);
  Say('median', Median(Values));
  Say('min', Values[0]);
  Say('max', Values[N - 1]);
  Say('range', Values[N - 1] - Values[0]);
  Say('variance', Variance);
  Say('std_dev', Sqrt(Variance));
end.
