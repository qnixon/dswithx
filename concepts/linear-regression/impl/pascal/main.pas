{ Simple linear regression by least squares, using only Free Pascal's
  run-time library.

  Fits score = intercept + slope * hours. The Math unit has Mean and
  TotalVariance, but they are left out here, so every sum is a loop over
  two arrays of doubles. }
program LinearRegression;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils;

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

procedure Say(const Name: String; Value: Double);
begin
  WriteLn(Name, ' ', Value:0:6);  // width 0, six decimals
end;

var
  Xs, Ys: TDoubleArray;
  N, I: Integer;
  SumX, SumY, MeanX, MeanY, Dx, Dy, Sxx, Syy, Sxy: Double;
  Slope, Intercept, R: Double;
begin
  // Each column is read on its own; row I of the file is Xs[I] and Ys[I].
  Xs := ReadColumn(ParamStr(1), 'hours');
  Ys := ReadColumn(ParamStr(1), 'score');
  N := Length(Xs);
  if Length(Ys) <> N then  // <> is "not equal"
    raise Exception.Create('columns differ in length');

  // First pass: the means.
  SumX := 0;
  SumY := 0;
  for I := 0 to N - 1 do
  begin
    SumX := SumX + Xs[I];
    SumY := SumY + Ys[I];
  end;
  MeanX := SumX / N;
  MeanY := SumY / N;

  // Second pass: sums of squared deviations and of cross-products.
  Sxx := 0;
  Syy := 0;
  Sxy := 0;
  for I := 0 to N - 1 do
  begin
    Dx := Xs[I] - MeanX;
    Dy := Ys[I] - MeanY;
    Sxx := Sxx + Dx * Dx;
    Syy := Syy + Dy * Dy;
    Sxy := Sxy + Dx * Dy;
  end;

  Slope := Sxy / Sxx;
  Intercept := MeanY - Slope * MeanX;
  R := Sxy / Sqrt(Sxx * Syy);

  WriteLn('count ', N);
  Say('slope', Slope);
  Say('intercept', Intercept);
  Say('r', R);
  Say('r_squared', R * R);
end.
