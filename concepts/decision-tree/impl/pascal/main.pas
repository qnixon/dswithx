{ A decision tree classifier (CART with Gini impurity), using only Free
  Pascal's run-time library.

  Grows a tree on the training days by always making the split that leaves
  the two sides purest, then predicts rain for the test days. Prints the
  tree in preorder: each node is either a split (feature and threshold) or
  a leaf (its prediction). The run-time library has no tree or classifier,
  so there is none to skip; sorting uses TArrayHelper from
  Generics.Collections. }
program DecisionTree;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils, Generics.Collections;

const
  NFeatures = 3;
  MaxDepth = 3;
  MinSize = 5;
  Features: array[0..NFeatures - 1] of String = ('humidity', 'pressure', 'wind');

type
  TDoubleArray = array of Double;

  TDay = record
    X: array[0..NFeatures - 1] of Double;
    Rain: Boolean;
  end;
  TDayArray = array of TDay;

  { ^TNode is a pointer to a TNode. Pascal lets PNode name TNode before
    TNode is declared, as long as both are in the same type section. A leaf
    is a node whose children are nil. }
  PNode = ^TNode;
  TNode = record
    Feature: Integer;
    Threshold: Double;
    Left, Right: PNode;
    Rain: Boolean;
  end;

function Column(const Header: TStringArray; const Name: String): Integer;
var
  I: Integer;
begin
  for I := 0 to High(Header) do
    if Header[I] = Name then
      Exit(I);
  raise Exception.Create('column not found: ' + Name);
end;

procedure Append(var Days: TDayArray; const D: TDay);
begin
  SetLength(Days, Length(Days) + 1);  // grow by one
  Days[High(Days)] := D;
end;

procedure ReadDays(const Path: String; out Train, Test: TDayArray);
var
  F: TextFile;
  Line: String;
  Fields: TStringArray;
  Cols: array[0..NFeatures - 1] of Integer;
  RainCol, SplitCol, I: Integer;
  D: TDay;
begin
  Train := nil;
  Test := nil;
  AssignFile(F, Path);
  Reset(F);
  ReadLn(F, Line);
  Fields := Line.Split(',');
  for I := 0 to NFeatures - 1 do
    Cols[I] := Column(Fields, Features[I]);
  RainCol := Column(Fields, 'rain');
  SplitCol := Column(Fields, 'split');
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Fields := Line.Split(',');
    for I := 0 to NFeatures - 1 do
      D.X[I] := StrToFloat(Fields[Cols[I]]);
    D.Rain := Fields[RainCol] = 'yes';
    if Fields[SplitCol] = 'train' then
      Append(Train, D)
    else
      Append(Test, D);
  end;
  CloseFile(F);
end;

function CountYes(const Days: TDayArray): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Days) do
    if Days[I].Rain then
      Inc(Result);
end;

{ The chance that two days drawn at random (with replacement) disagree. }
function Gini(const Days: TDayArray): Double;
var
  P: Double;
begin
  P := CountYes(Days) / Length(Days);
  Result := 1 - Sqr(P) - Sqr(1 - P);
end;

{ The days at or below the threshold go left, the rest go right. }
procedure Partition(const Days: TDayArray; F: Integer; Threshold: Double;
  out Left, Right: TDayArray);
var
  I: Integer;
begin
  Left := nil;
  Right := nil;
  for I := 0 to High(Days) do
    if Days[I].X[F] <= Threshold then
      Append(Left, Days[I])
    else
      Append(Right, Days[I]);
end;

{ Find the split with the lowest weighted Gini impurity. Features are tried
  in column order and thresholds from smallest to largest; only a strictly
  lower score replaces the best so far. Returns False if no feature has two
  distinct values. }
function BestSplit(const Days: TDayArray; out Score: Double;
  out Feature: Integer; out Threshold: Double): Boolean;
var
  Values: TDoubleArray;
  Left, Right: TDayArray;
  F, I, Distinct, N: Integer;
  T, S: Double;
begin
  Result := False;
  Score := 0;
  Feature := 0;
  Threshold := 0;
  N := Length(Days);
  SetLength(Values, N);
  for F := 0 to NFeatures - 1 do
  begin
    for I := 0 to N - 1 do
      Values[I] := Days[I].X[F];
    specialize TArrayHelper<Double>.Sort(Values);
    // Drop repeats, which sit next to each other once sorted.
    Distinct := 1;
    for I := 1 to N - 1 do
      if Values[I] <> Values[Distinct - 1] then
      begin
        Values[Distinct] := Values[I];
        Inc(Distinct);
      end;

    for I := 1 to Distinct - 1 do
    begin
      T := (Values[I - 1] + Values[I]) / 2;
      Partition(Days, F, T, Left, Right);
      S := (Length(Left) * Gini(Left) + Length(Right) * Gini(Right)) / N;
      if (not Result) or (S < Score) then
      begin
        Score := S;
        Feature := F;
        Threshold := T;
        Result := True;
      end;
    end;
  end;
end;

{ New allocates a node on the heap and points the given pointer at it. }
function NewLeaf(const Days: TDayArray): PNode;
begin
  New(Result);
  Result^.Left := nil;
  Result^.Right := nil;
  Result^.Rain := 2 * CountYes(Days) > Length(Days);  // an even split says no
end;

{ Grow a tree on Days, calling itself on each side of the best split. }
function Grow(const Days: TDayArray; Depth: Integer): PNode;
var
  G, Score, Threshold: Double;
  F: Integer;
  Left, Right: TDayArray;
begin
  G := Gini(Days);
  if (G = 0) or (Length(Days) < MinSize) or (Depth = MaxDepth) then
    Exit(NewLeaf(Days));
  if not BestSplit(Days, Score, F, Threshold) or (Score >= G) then
    Exit(NewLeaf(Days));  // no split makes the sides purer

  Partition(Days, F, Threshold, Left, Right);
  New(Result);
  Result^.Feature := F;
  Result^.Threshold := Threshold;
  Result^.Left := Grow(Left, Depth + 1);
  Result^.Right := Grow(Right, Depth + 1);
  Result^.Rain := False;  // unused on a split
end;

function Predict(Node: PNode; const D: TDay): Boolean;
begin
  while Node^.Left <> nil do
    if D.X[Node^.Feature] <= Node^.Threshold then
      Node := Node^.Left
    else
      Node := Node^.Right;
  Result := Node^.Rain;
end;

procedure Say(const Name: String; Value: Double);
begin
  WriteLn(Name, ' ', Value:0:6);  // width 0, six decimals
end;

{ Print every node, parents before children, left before right. K is the
  running node number and Leaves the running leaf count; var passes them by
  reference so the calls share one copy. }
procedure PrintPreorder(Node: PNode; var K, Leaves: Integer);
var
  Id: String;
begin
  Inc(K);
  Id := 'node_' + IntToStr(K);
  if Node^.Left = nil then
  begin
    if Node^.Rain then
      WriteLn(Id, '_predict yes')
    else
      WriteLn(Id, '_predict no');
    Inc(Leaves);
    Exit;
  end;
  WriteLn(Id, '_feature ', Features[Node^.Feature]);
  Say(Id + '_threshold', Node^.Threshold);
  PrintPreorder(Node^.Left, K, Leaves);
  PrintPreorder(Node^.Right, K, Leaves);
end;

function CountCorrect(Tree: PNode; const Days: TDayArray): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to High(Days) do
    if Predict(Tree, Days[I]) = Days[I].Rain then
      Inc(Result);
end;

{ Nothing frees heap memory for you: dispose of the children, then the node. }
procedure FreeTree(Node: PNode);
begin
  if Node^.Left <> nil then
  begin
    FreeTree(Node^.Left);
    FreeTree(Node^.Right);
  end;
  Dispose(Node);
end;

var
  Train, Test: TDayArray;
  Tree: PNode;
  K, Leaves, Correct: Integer;
begin
  ReadDays(ParamStr(1), Train, Test);
  Tree := Grow(Train, 0);

  WriteLn('train_count ', Length(Train));
  WriteLn('test_count ', Length(Test));
  K := 0;
  Leaves := 0;
  PrintPreorder(Tree, K, Leaves);
  WriteLn('leaves ', Leaves);

  Correct := CountCorrect(Tree, Test);
  Say('train_accuracy', CountCorrect(Tree, Train) / Length(Train));
  WriteLn('correct ', Correct);
  Say('accuracy', Correct / Length(Test));

  FreeTree(Tree);
end.
