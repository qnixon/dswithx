{ 5-fold cross-validation for k-nearest neighbors, using only Free Pascal's
  run-time library.

  Splits the training seeds into 5 folds, scores each odd K from 1 to 15 by
  holding out one fold at a time, picks the K with the best average
  accuracy, and then scores that K once on the untouched test seeds. }
program CrossValidation;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils, Generics.Collections, Generics.Defaults;

const
  Folds = 5;

type
  // A record groups one seed's measurements with its variety.
  TSeed = record
    LengthMm, WidthMm: Double;
    Variety: String;
  end;
  TSeedArray = array of TSeed;

  // A training seed's distance from the point, and its row in Train.
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

function Classify(const Point: TSeed; const Train: TSeedArray; K: Integer): String;
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

function CountCorrect(const Points, Train: TSeedArray; K: Integer): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Points) do
    if Classify(Points[I], Train, K) = Points[I].Variety then
      Inc(Result);
end;

function CVAccuracy(const Train: TSeedArray; K: Integer): Double;
var
  Size, F, Start, Stop, Correct: Integer;
begin
  // Fold F is rows F*Size up to (F+1)*Size. The rows are already shuffled,
  // so consecutive blocks make fair folds.
  Size := Length(Train) div Folds;
  Correct := 0;
  for F := 0 to Folds - 1 do
  begin
    Start := F * Size;
    Stop := (F + 1) * Size;
    // Copy(A, From, Count) copies Count elements of a dynamic array, and
    // Concat joins the rows before and after the held-out block.
    Correct := Correct + CountCorrect(Copy(Train, Start, Size),
      Concat(Copy(Train, 0, Start), Copy(Train, Stop, Length(Train) - Stop)), K);
  end;
  Result := Correct / Length(Train);
end;

var
  Lengths, Widths, Varieties, Splits: TStringArray;
  Train, Test: TSeedArray;
  Seed: TSeed;
  I, K, BestK, Correct: Integer;
  Accuracy, BestAccuracy: Double;
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

  WriteLn('train_count ', Length(Train));
  WriteLn('test_count ', Length(Test));
  BestK := 0;
  BestAccuracy := -1.0;
  // Pascal's for loop only steps by one, so I counts 0 to 7 and K is the
  // odd number 2I + 1. Odd K only, so two varieties can't tie.
  for I := 0 to 7 do
  begin
    K := 2 * I + 1;
    Accuracy := CVAccuracy(Train, K);
    WriteLn('cv_accuracy_k', K, ' ', Accuracy:0:6);
    if Accuracy > BestAccuracy then  // strictly better, so ties keep the smaller K
    begin
      BestK := K;
      BestAccuracy := Accuracy;
    end;
  end;

  // Only now touch the test seeds, once, with the chosen K and all of Train.
  Correct := CountCorrect(Test, Train, BestK);
  WriteLn('best_k ', BestK);
  WriteLn('test_correct ', Correct);
  WriteLn('test_accuracy ', Correct / Length(Test):0:6);
end.
