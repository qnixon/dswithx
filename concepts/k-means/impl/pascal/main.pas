{ k-means clustering (Lloyd's algorithm), using only Free Pascal's run-time
  library.

  Starts from the first K points as centroids, then alternates two steps
  until no point changes cluster: assign each point to its nearest centroid,
  and move each centroid to the mean of its points. None of the installed
  units has a k-means routine, so there is no built-in to avoid. }
program KMeans;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils;

const
  K = 3;
  MaxIterations = 100;

type
  // A record is a value: assigning one copies both fields.
  TPoint = record
    X, Y: Double;
  end;
  TPointArray = array of TPoint;
  TCentroids = array[0..K - 1] of TPoint;  // a fixed-size array, indexed 0..2

function ReadPoints(const Path: String): TPointArray;
var
  F: TextFile;
  Line: String;
  Fields: TStringArray;
  XCol, YCol, I: Integer;
begin
  Result := nil;
  AssignFile(F, Path);
  Reset(F);
  ReadLn(F, Line);
  Fields := Line.Split(',');
  XCol := -1;
  YCol := -1;
  for I := 0 to High(Fields) do
  begin
    if Fields[I] = 'x' then XCol := I;
    if Fields[I] = 'y' then YCol := I;
  end;
  if (XCol < 0) or (YCol < 0) then
    raise Exception.Create('no x or y column');
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    if Line = '' then
      Continue;
    Fields := Line.Split(',');
    SetLength(Result, Length(Result) + 1);  // grow by one
    Result[High(Result)].X := StrToFloat(Fields[XCol]);
    Result[High(Result)].Y := StrToFloat(Fields[YCol]);
  end;
  CloseFile(F);
end;

{ Squared Euclidean distance. It ranks centroids in the same order as the
  distance itself, so the nearest one needs no Sqrt. }
function SquaredDistance(const A, B: TPoint): Double;
begin
  Result := Sqr(A.X - B.X) + Sqr(A.Y - B.Y);
end;

{ The index of the closest centroid. Only a strictly smaller distance
  replaces the best so far, so a tie goes to the lower index. }
function Nearest(const P: TPoint; const Centroids: TCentroids): Integer;
var
  J: Integer;
begin
  Result := 0;
  for J := 1 to K - 1 do
    if SquaredDistance(P, Centroids[J]) < SquaredDistance(P, Centroids[Result]) then
      Result := J;
end;

procedure Say(const Name: String; Value: Double);
begin
  WriteLn(Name, ' ', Value:0:6);  // width 0, six decimals
end;

var
  Points: TPointArray;
  Centroids, Sums: TCentroids;
  Assignment: array of Integer;
  Sizes: array[0..K - 1] of Integer;
  N, I, J, Iterations: Integer;
  Changed: Boolean;
  Inertia: Double;
begin
  Points := ReadPoints(ParamStr(1));
  N := Length(Points);
  if N < K then
    raise Exception.Create('need at least 3 points');

  for J := 0 to K - 1 do
    Centroids[J] := Points[J];  // a copy, so moving a centroid leaves the point alone

  // -1 means "no cluster yet", so the first pass always counts as a change.
  SetLength(Assignment, N);
  for I := 0 to N - 1 do
    Assignment[I] := -1;

  Iterations := 0;
  while Iterations < MaxIterations do
  begin
    Inc(Iterations);
    Changed := False;
    for I := 0 to N - 1 do
    begin
      J := Nearest(Points[I], Centroids);
      if J <> Assignment[I] then
      begin
        Assignment[I] := J;
        Changed := True;
      end;
    end;
    if not Changed then
      Break;

    // Sum each cluster's points in one pass, then divide by its size.
    for J := 0 to K - 1 do
    begin
      Sums[J].X := 0;
      Sums[J].Y := 0;
      Sizes[J] := 0;
    end;
    for I := 0 to N - 1 do
    begin
      J := Assignment[I];
      Sums[J].X := Sums[J].X + Points[I].X;
      Sums[J].Y := Sums[J].Y + Points[I].Y;
      Inc(Sizes[J]);
    end;
    for J := 0 to K - 1 do
      if Sizes[J] > 0 then  // an empty cluster keeps its old centroid
      begin
        Centroids[J].X := Sums[J].X / Sizes[J];
        Centroids[J].Y := Sums[J].Y / Sizes[J];
      end;
  end;

  for J := 0 to K - 1 do
    Sizes[J] := 0;
  Inertia := 0;
  for I := 0 to N - 1 do
  begin
    Inc(Sizes[Assignment[I]]);
    Inertia := Inertia + SquaredDistance(Points[I], Centroids[Assignment[I]]);
  end;

  // Clusters are numbered from 0 inside the program and from 1 in the output.
  WriteLn('iterations ', Iterations);
  for J := 0 to K - 1 do
  begin
    Say('centroid_' + IntToStr(J + 1) + '_x', Centroids[J].X);
    Say('centroid_' + IntToStr(J + 1) + '_y', Centroids[J].Y);
  end;
  for J := 0 to K - 1 do
    WriteLn('size_', J + 1, ' ', Sizes[J]);
  Say('inertia', Inertia);
end.
