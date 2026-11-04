{ Train and test error for polynomials of degree 1 to 8, using only Free
  Pascal's run-time library.

  Each polynomial is fitted by least squares to the training drives only:
  we build the normal equations and solve them by Gaussian elimination.
  Then we measure its root-mean-square error on the training drives and on
  the test drives it never saw. }
program TrainAndTest;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils;

const
  MaxDegree = 8;
  MaxSize = MaxDegree + 1;  // unknowns in the largest system

type
  TPoint = record
    X, Y: Double;
  end;
  TPoints = array of TPoint;  // a dynamic array, counted from 0
  // Fixed arrays big enough for the largest system; a smaller degree uses
  // the top-left corner. Column MaxSize + 1 holds the right-hand side.
  TMatrix = array[0..MaxSize - 1, 0..MaxSize] of Double;
  TVector = array[0..MaxSize - 1] of Double;

var
  Mid, Half: Double;  // the scale, set from the training speeds

procedure Append(var Points: TPoints; X, Y: Double);
begin
  SetLength(Points, Length(Points) + 1);  // grow by one
  Points[High(Points)].X := X;
  Points[High(Points)].Y := Y;
end;

{ Read every drive into the training or the test points. }
procedure ReadDrives(const Path: String; out Train, Test: TPoints);
var
  F: TextFile;
  Line: String;
  Fields: TStringArray;
  I, SpeedCol, LitresCol, SplitCol: Integer;
  X, Y: Double;
begin
  Train := nil;
  Test := nil;
  AssignFile(F, Path);
  Reset(F);
  ReadLn(F, Line);
  Fields := Line.Split(',');
  SpeedCol := -1;
  LitresCol := -1;
  SplitCol := -1;
  for I := 0 to High(Fields) do
    if Fields[I] = 'speed' then SpeedCol := I
    else if Fields[I] = 'litres' then LitresCol := I
    else if Fields[I] = 'split' then SplitCol := I;
  if (SpeedCol < 0) or (LitresCol < 0) or (SplitCol < 0) then
    raise Exception.Create('missing column');
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Fields := Line.Split(',');
    X := StrToFloat(Fields[SpeedCol]);
    Y := StrToFloat(Fields[LitresCol]);
    if Fields[SplitCol] = 'train' then
      Append(Train, X, Y)
    else
      Append(Test, X, Y);
  end;
  CloseFile(F);
end;

function Scale(X: Double): Double;
begin
  Result := (X - Mid) / Half;
end;

{ Solve the N equations in the augmented matrix M by Gaussian elimination
  with partial pivoting. M is a copy (no var), so the caller's is kept. }
function Solve(M: TMatrix; N: Integer): TVector;
var
  Col, R, C, Pivot: Integer;
  Factor, Temp, Total: Double;
  X: TVector;
begin
  // With warnings as errors, X must be set before the compiler sees it read.
  FillChar(X, SizeOf(X), 0);
  for Col := 0 to N - 1 do
  begin
    // Swap up the row with the largest entry in this column, which keeps
    // the rounding error small.
    Pivot := Col;
    for R := Col + 1 to N - 1 do
      if Abs(M[R, Col]) > Abs(M[Pivot, Col]) then
        Pivot := R;
    for C := 0 to N do
    begin
      Temp := M[Col, C];
      M[Col, C] := M[Pivot, C];
      M[Pivot, C] := Temp;
    end;
    for R := Col + 1 to N - 1 do
    begin
      Factor := M[R, Col] / M[Col, Col];
      for C := Col to N do
        M[R, C] := M[R, C] - Factor * M[Col, C];
    end;
  end;
  // Back substitution, from the last unknown up.
  for R := N - 1 downto 0 do
  begin
    Total := M[R, N];
    for C := R + 1 to N - 1 do
      Total := Total - M[R, C] * X[C];
    X[R] := Total / M[R, R];
  end;
  Result := X;
end;

{ Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
  Z is 1, z_i, z_i^2, ..., z_i^Degree. }
function Fit(const Points: TPoints; Degree: Integer): TVector;
var
  M: TMatrix;
  Powers: array[0..2 * MaxDegree] of Double;
  P, I, J: Integer;
begin
  FillChar(M, SizeOf(M), 0);  // set every byte to 0, which is 0.0
  for P := 0 to High(Points) do
  begin
    Powers[0] := 1;
    for I := 1 to 2 * Degree do
      Powers[I] := Powers[I - 1] * Scale(Points[P].X);
    for I := 0 to Degree do
    begin
      M[I, Degree + 1] := M[I, Degree + 1] + Points[P].Y * Powers[I];
      for J := 0 to Degree do
        M[I, J] := M[I, J] + Powers[I + J];
    end;
  end;
  Result := Solve(M, Degree + 1);
end;

function Rmse(const Coefs: TVector; Degree: Integer; const Points: TPoints): Double;
var
  P, I: Integer;
  Predicted, Total: Double;
begin
  Total := 0;
  for P := 0 to High(Points) do
  begin
    // Horner's rule: c0 + z (c1 + z (c2 + ...)).
    Predicted := 0;
    for I := Degree downto 0 do
      Predicted := Predicted * Scale(Points[P].X) + Coefs[I];
    Total := Total + Sqr(Predicted - Points[P].Y);
  end;
  Result := Sqrt(Total / Length(Points));
end;

var
  Train, Test: TPoints;
  Coefs: TVector;
  TrainErrors, TestErrors: array[1..MaxDegree] of Double;
  LowX, HighX: Double;
  Degree, I: Integer;
begin
  ReadDrives(ParamStr(1), Train, Test);

  // Map the training speeds onto -1 to 1. Raw speeds to the 16th power
  // (the largest entry at degree 8) would swamp the small ones and make
  // the equations hard to solve accurately.
  LowX := Train[0].X;
  HighX := LowX;
  for I := 1 to High(Train) do
  begin
    if Train[I].X < LowX then LowX := Train[I].X;
    if Train[I].X > HighX then HighX := Train[I].X;
  end;
  Mid := (LowX + HighX) / 2;
  Half := (HighX - LowX) / 2;

  WriteLn('train_count ', Length(Train));
  WriteLn('test_count ', Length(Test));
  for Degree := 1 to MaxDegree do
  begin
    Coefs := Fit(Train, Degree);
    TrainErrors[Degree] := Rmse(Coefs, Degree, Train);
    TestErrors[Degree] := Rmse(Coefs, Degree, Test);
  end;
  for Degree := 1 to MaxDegree do
    WriteLn('train_rmse_d', Degree, ' ', TrainErrors[Degree]:0:6);  // six decimals
  for Degree := 1 to MaxDegree do
    WriteLn('test_rmse_d', Degree, ' ', TestErrors[Degree]:0:6);
end.
