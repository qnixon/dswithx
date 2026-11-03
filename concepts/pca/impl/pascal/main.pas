{ Principal component analysis by power iteration, using only Free
  Pascal's run-time library.

  Standardizes the four scores, builds their correlation matrix, and finds
  the top two eigenvectors (the principal components): power iteration
  finds the first, then deflation removes it from the matrix so the same
  steps find the second. The Math unit's Mean and StdDev are left out, and no
  installed unit has an eigenvalue routine to skip. }
program PrincipalComponents;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils;

const
  K = 4;  // subjects
  Steps = 1000;
  Subjects: array[1..K] of String = ('math', 'physics', 'reading', 'writing');

type
  // Array bounds are part of the type, so these count from 1, not 0.
  TVector = array[1..K] of Double;
  TMatrix = array[1..K, 1..K] of Double;
  TRows = array of TVector;  // a dynamic array, counted from 0

{ Read the four subject columns, found by name, into rows of K scores. }
function ReadScores(const Path: String): TRows;
var
  F: TextFile;
  Line: String;
  Fields: TStringArray;
  Cols: array[1..K] of Integer;
  I, J: Integer;
begin
  Result := nil;
  AssignFile(F, Path);
  Reset(F);
  ReadLn(F, Line);
  Fields := Line.Split(',');
  for J := 1 to K do
  begin
    Cols[J] := -1;
    for I := 0 to High(Fields) do
      if Fields[I] = Subjects[J] then
        Cols[J] := I;
    if Cols[J] < 0 then
      raise Exception.Create('column not found: ' + Subjects[J]);
  end;
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Fields := Line.Split(',');
    SetLength(Result, Length(Result) + 1);  // grow by one
    for J := 1 to K do
      Result[High(Result)][J] := StrToFloat(Fields[Cols[J]]);
  end;
  CloseFile(F);
end;

{ M V. Unlike C, a Pascal function can return a fixed-size array. }
function MatVec(const M: TMatrix; const V: TVector): TVector;
var
  I, J: Integer;
begin
  for I := 1 to K do
  begin
    Result[I] := 0;
    for J := 1 to K do
      Result[I] := Result[I] + M[I, J] * V[J];
  end;
end;

function Dot(const U, V: TVector): Double;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to K do
    Result := Result + U[I] * V[I];
end;

{ Power iteration: multiply by the matrix and rescale, Steps times. Fills
  V with the eigenvector and returns its eigenvalue. }
function TopEigenvector(const M: TMatrix; out V: TVector): Double;
var
  MV: TVector;
  Len: Double;
  I, Step: Integer;
begin
  for I := 1 to K do
    V[I] := 0;
  V[1] := 1;
  for Step := 1 to Steps do
  begin
    MV := MatVec(M, V);
    Len := Sqrt(Dot(MV, MV));
    for I := 1 to K do
      V[I] := MV[I] / Len;
  end;
  // An eigenvector can point either way; make its first entry positive.
  if V[1] < 0 then
    for I := 1 to K do
      V[I] := -V[I];
  Result := Dot(V, MatVec(M, V));  // the Rayleigh quotient v . (M v)
end;

procedure Say(const Name: String; Value: Double);
begin
  WriteLn(Name, ' ', Value:0:6);  // width 0, six decimals
end;

procedure Report(C: Integer; Value: Double; const PC: TVector);
var
  J: Integer;
begin
  Say('eigenvalue_' + IntToStr(C), Value);
  // Standardized columns each have variance 1, so the total is K.
  Say('explained_' + IntToStr(C), Value / K);
  for J := 1 to K do
    Say('pc' + IntToStr(C) + '_' + Subjects[J], PC[J]);
end;

var
  Z: TRows;
  Corr, Deflated: TMatrix;
  PC1, PC2: TVector;
  Value1, Value2, Total, Squares, Mean, Sd: Double;
  N, I, A, B: Integer;
begin
  Z := ReadScores(ParamStr(1));
  N := Length(Z);

  // Standardize each column to mean 0 and (sample) standard deviation 1.
  for A := 1 to K do
  begin
    Total := 0;
    for I := 0 to N - 1 do
      Total := Total + Z[I][A];
    Mean := Total / N;
    Squares := 0;
    for I := 0 to N - 1 do
      Squares := Squares + Sqr(Z[I][A] - Mean);
    Sd := Sqrt(Squares / (N - 1));
    for I := 0 to N - 1 do
      Z[I][A] := (Z[I][A] - Mean) / Sd;
  end;

  // The correlation matrix: the covariance of the standardized columns.
  for A := 1 to K do
    for B := 1 to K do
    begin
      Total := 0;
      for I := 0 to N - 1 do
        Total := Total + Z[I][A] * Z[I][B];
      Corr[A, B] := Total / (N - 1);
    end;

  Value1 := TopEigenvector(Corr, PC1);
  // Deflation: subtract the first component's share, leaving the rest.
  for A := 1 to K do
    for B := 1 to K do
      Deflated[A, B] := Corr[A, B] - Value1 * PC1[A] * PC1[B];
  Value2 := TopEigenvector(Deflated, PC2);

  WriteLn('count ', N);
  Report(1, Value1, PC1);
  Report(2, Value2, PC2);
  // Z is a dynamic array, counted from 0, so the first student is Z[0].
  Say('student_1_pc1', Dot(Z[0], PC1));
  Say('student_1_pc2', Dot(Z[0], PC2));
end.
