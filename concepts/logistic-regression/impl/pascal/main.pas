{ Logistic regression by gradient descent, using only Free Pascal's
  run-time library.

  Predicts whether a student passed from study hours and sleep. Each
  feature is rescaled with the training rows' mean and standard deviation,
  then the weights start at zero and take Steps fixed steps of batch
  gradient descent on the average log-loss. The Math unit's Mean and
  StdDev are left out, so the scaling is written out too. }
program LogisticRegression;

{$mode objfpc}{$H+}  // 32-bit Integer, and strings longer than 255 characters

uses
  SysUtils;

const
  K = 3;  // inputs per row: 1 (for the intercept), hours, sleep
  LearningRate = 0.5;
  Steps = 1000;

type
  TVector = array[0..K - 1] of Double;  // a fixed-size array type
  TExample = record
    X: TVector;  // X[0] is always 1, so weight 0 acts as the intercept
    Y: Integer;
  end;
  TExamples = array of TExample;

procedure Append(var Rows: TExamples; const Row: TExample);
begin
  SetLength(Rows, Length(Rows) + 1);  // grow by one
  Rows[High(Rows)] := Row;
end;

function Column(const Header: TStringArray; const Name: String): Integer;
var
  I: Integer;
begin
  for I := 0 to High(Header) do
    if Header[I] = Name then
      Exit(I);  // Exit(value) sets the result and returns
  raise Exception.Create('column not found: ' + Name);
end;

{ Read the CSV into training and test rows, sorted by the "split" column. }
procedure ReadRows(const Path: String; out Train, Test: TExamples);
var
  F: TextFile;
  Line: String;
  Fields: TStringArray;
  CHours, CSleep, CPassed, CSplit: Integer;
  Row: TExample;
begin
  Train := nil;
  Test := nil;
  AssignFile(F, Path);
  Reset(F);
  ReadLn(F, Line);
  Fields := Line.Split(',');
  CHours := Column(Fields, 'hours');
  CSleep := Column(Fields, 'sleep');
  CPassed := Column(Fields, 'passed');
  CSplit := Column(Fields, 'split');
  while not Eof(F) do
  begin
    ReadLn(F, Line);
    Fields := Line.Split(',');
    Row.X[0] := 1;
    Row.X[1] := StrToFloat(Fields[CHours]);
    Row.X[2] := StrToFloat(Fields[CSleep]);
    Row.Y := StrToInt(Fields[CPassed]);
    if Fields[CSplit] = 'train' then
      Append(Train, Row)
    else
      Append(Test, Row);
  end;
  CloseFile(F);
end;

{ The probability of passing: the sigmoid of the weighted sum of inputs. }
function Predict(const W, X: TVector): Double;
var
  J: Integer;
  Z: Double;
begin
  Z := 0;
  for J := 0 to K - 1 do
    Z := Z + W[J] * X[J];
  Result := 1 / (1 + Exp(-Z));
end;

procedure Say(const Name: String; Value: Double);
begin
  WriteLn(Name, ' ', Value:0:6);  // width 0, six decimals
end;

var
  Train, Test: TExamples;
  W, Gradient: TVector;
  N, I, J, Step, Correct: Integer;
  Total, Squares, Mean, Sd, Error, P, Loss: Double;
begin
  ReadRows(ParamStr(1), Train, Test);
  N := Length(Train);

  // Scale each feature to mean 0 and (sample) standard deviation 1, using
  // the training rows only, then apply the same shift to the test rows.
  // Column 0 holds the ones, so the features are columns 1 and 2.
  for J := 1 to K - 1 do
  begin
    Total := 0;
    for I := 0 to N - 1 do
      Total := Total + Train[I].X[J];
    Mean := Total / N;
    Squares := 0;
    for I := 0 to N - 1 do
      Squares := Squares + Sqr(Train[I].X[J] - Mean);
    Sd := Sqrt(Squares / (N - 1));
    for I := 0 to N - 1 do
      Train[I].X[J] := (Train[I].X[J] - Mean) / Sd;
    for I := 0 to High(Test) do
      Test[I].X[J] := (Test[I].X[J] - Mean) / Sd;
  end;

  for J := 0 to K - 1 do
    W[J] := 0;
  for Step := 1 to Steps do
  begin
    // Gradient of the average log-loss: the mean of (p - y) times each
    // input. It is summed over every student before any weight moves.
    for J := 0 to K - 1 do
      Gradient[J] := 0;
    for I := 0 to N - 1 do
    begin
      Error := Predict(W, Train[I].X) - Train[I].Y;
      for J := 0 to K - 1 do
        Gradient[J] := Gradient[J] + Error * Train[I].X[J];
    end;
    for J := 0 to K - 1 do
      W[J] := W[J] - LearningRate * Gradient[J] / N;
  end;

  Loss := 0;
  for I := 0 to N - 1 do
  begin
    P := Predict(W, Train[I].X);
    if Train[I].Y = 1 then
      Loss := Loss - Ln(P)
    else
      Loss := Loss - Ln(1 - P);
  end;
  Loss := Loss / N;

  Correct := 0;
  for I := 0 to High(Test) do
    // Ord turns a Boolean into 0 or 1, so it compares with the label.
    if Ord(Predict(W, Test[I].X) >= 0.5) = Test[I].Y then
      Inc(Correct);

  WriteLn('train_count ', N);
  WriteLn('test_count ', Length(Test));
  Say('intercept', W[0]);
  Say('weight_hours', W[1]);
  Say('weight_sleep', W[2]);
  Say('log_loss', Loss);
  WriteLn('correct ', Correct);
  Say('accuracy', Correct / Length(Test));  // / gives a real, even for integers
end.
