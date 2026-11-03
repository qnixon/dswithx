{ k-nearest neighbors classification, using only Free Pascal's run-time
  library.

  Each test seed is labelled with the majority variety among its K nearest
  training seeds, by Euclidean distance. There is no classifier to avoid;
  sorting uses TArrayHelper from Generics.Collections, and the votes are
  counted in a loop. }
program KNearestNeighbors;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils, Generics.Collections, Generics.Defaults;

const
  K = 5;

type
  // A record groups one seed's measurements with its variety.
  TSeed = record
    LengthMm, WidthMm: Double;
    Variety: String;
  end;
  TSeedArray = array of TSeed;

  // A training seed's distance from the test seed, and its row in the file.
  TNeighbor = record
    Distance: Double;
    Index: Integer;
  end;
  TNeighborArray = array of TNeighbor;

// The named column of a CSV file, as text. Numbers are parsed by the
// caller, since the variety and split columns are words.
function ReadColumn(const Path, Name: String): TStringArray;
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
    Result[High(Result)] := Fields[Col];
  end;
  CloseFile(F);
end;

// TArrayHelper.Sort is a quicksort, which doesn't keep equal elements in
// order, so equal distances fall back to file order.
function CompareNeighbors(constref A, B: TNeighbor): Integer;
begin
  if A.Distance < B.Distance then Result := -1
  else if A.Distance > B.Distance then Result := 1
  else Result := A.Index - B.Index;
end;

function Classify(const Point: TSeed; const Train: TSeedArray): String;
var
  Neighbors: TNeighborArray;
  I, J, Votes, BestVotes: Integer;
begin
  Neighbors := nil;
  SetLength(Neighbors, Length(Train));
  for I := 0 to High(Train) do
  begin
    Neighbors[I].Distance := Sqrt(Sqr(Point.LengthMm - Train[I].LengthMm) +
                                  Sqr(Point.WidthMm - Train[I].WidthMm));
    Neighbors[I].Index := I;
  end;
  // @ passes the function itself, not a call to it.
  specialize TArrayHelper<TNeighbor>.Sort(Neighbors,
    specialize TComparer<TNeighbor>.Construct(@CompareNeighbors));

  // Count each of the K nearest labels' votes among the K; the first label
  // to reach the highest count wins.
  Result := '';
  BestVotes := 0;
  for I := 0 to K - 1 do
  begin
    Votes := 0;
    for J := 0 to K - 1 do
      if Train[Neighbors[J].Index].Variety = Train[Neighbors[I].Index].Variety then
        Inc(Votes);
    if Votes > BestVotes then
    begin
      Result := Train[Neighbors[I].Index].Variety;
      BestVotes := Votes;
    end;
  end;
end;

var
  Lengths, Widths, Varieties, Splits: TStringArray;
  Train, Test: TSeedArray;
  Seed: TSeed;
  I, Correct: Integer;
begin
  Lengths := ReadColumn(ParamStr(1), 'length_mm');
  Widths := ReadColumn(ParamStr(1), 'width_mm');
  Varieties := ReadColumn(ParamStr(1), 'variety');
  Splits := ReadColumn(ParamStr(1), 'split');

  Train := nil;
  Test := nil;
  for I := 0 to High(Lengths) do
  begin
    Seed.LengthMm := StrToFloat(Lengths[I]);
    Seed.WidthMm := StrToFloat(Widths[I]);
    Seed.Variety := Varieties[I];
    // Strings compare by their text with =, and records copy by value.
    if Splits[I] = 'train' then
      Insert(Seed, Train, Length(Train))  // append
    else
      Insert(Seed, Test, Length(Test));
  end;

  Correct := 0;
  for I := 0 to High(Test) do
    if Classify(Test[I], Train) = Test[I].Variety then
      Inc(Correct);

  WriteLn('train_count ', Length(Train));
  WriteLn('test_count ', Length(Test));
  WriteLn('correct ', Correct);
  WriteLn('accuracy ', Correct / Length(Test):0:6);
end.
