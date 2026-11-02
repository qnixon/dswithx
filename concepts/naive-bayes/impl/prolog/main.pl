% Categorical naive Bayes with add-one (Laplace) smoothing, using
% SWI-Prolog and the libraries that come with it.
%
% Learns P(label) and P(feature value | label) by counting training rows,
% then labels each test row with the label that has the highest
% log-probability. Every cell of the CSV becomes a fact, and each count is
% a question asked of those facts, so there are no tables of counts.

:- initialization(main, main).

% cell(Row, Column, Value) facts are added while the program runs.
% Declaring cell/3 dynamic tells Prolog they can change, and makes a
% question about cells fail quietly, not raise an error, before any exist.
:- dynamic cell/3.

features(["has_link", "mentions_money", "known_sender"]).

% load_cells(+Path): add one cell fact for every value in the file, such as
% cell(1, "label", "spam") for row 1. Rows are numbered from 1.
load_cells(Path) :-
    read_file_to_string(Path, Text, []),
    split_string(Text, "\n", "", [HeaderLine|Lines]),
    split_string(HeaderLine, ",", "", Header),
    exclude(==(""), Lines, Rows),
    forall(nth1(Row, Rows, Line),
           ( split_string(Line, ",", "", Fields),
             forall(nth1(I, Header, Column),
                    ( nth1(I, Fields, Value),
                      assertz(cell(Row, Column, Value)) )) )).

% A row is in the training or the test set by its split column.
train(Row) :- cell(Row, "split", "train").
test(Row) :- cell(Row, "split", "test").

% label_count(+Label, -N): training rows with this label. aggregate_all
% counts how many ways the goal in the middle can succeed.
label_count(Label, N) :-
    aggregate_all(count, (train(Row), cell(Row, "label", Label)), N).

% value_count(+Feature, +Value, +Label, -N): training rows with this label
% whose Feature is Value. The key is just the three arguments.
value_count(Feature, Value, Label, N) :-
    aggregate_all(count,
                  ( train(Row),
                    cell(Row, "label", Label),
                    cell(Row, Feature, Value) ),
                  N).

% distinct_values(+Feature, -M): how many different values Feature takes
% in training. Here we want sort to drop repeats.
distinct_values(Feature, M) :-
    findall(Value, (train(Row), cell(Row, Feature, Value)), Values),
    sort(Values, Distinct),
    length(Distinct, M).

% log_score(+Row, +Label, -Score): log P(Label) plus the log of each
% feature's smoothed P(value | Label). Logs turn the product into a sum,
% avoiding underflow; adding one means no probability is ever zero.
log_score(Row, Label, Score) :-
    aggregate_all(count, train(_), N),
    label_count(Label, NC),
    features(Features),
    findall(Term,
            ( member(F, Features),
              cell(Row, F, Value),
              value_count(F, Value, Label, NV),
              distinct_values(F, M),
              Term is log((NV + 1) / (NC + M)) ),
            Terms),
    sum_list(Terms, Sum),
    Score is log(NC / N) + Sum.

% classify(+Row, -Best): the label with the highest score.
% aggregate_all(max(Score, Label), Goal, max(_, Best)) finds the highest
% Score over every solution of Goal and the Label that went with it. sort
% puts the labels in alphabetical order, and when several share the
% highest score, aggregate_all keeps the first: a tie goes to the
% alphabetically first label.
classify(Row, Best) :-
    findall(Label, (train(R), cell(R, "label", Label)), AllLabels),
    sort(AllLabels, Labels),
    aggregate_all(max(Score, Label),
                  ( member(Label, Labels),
                    log_score(Row, Label, Score) ),
                  max(_, Best)).

main :-
    current_prolog_flag(argv, [Path|_]),
    load_cells(Path),
    aggregate_all(count, train(_), TrainCount),
    aggregate_all(count, test(_), TestCount),
    % A test row counts as correct when its predicted label is its label.
    aggregate_all(count,
                  ( test(Row),
                    classify(Row, Predicted),
                    cell(Row, "label", Predicted) ),
                  Correct),
    Accuracy is Correct / TestCount,
    format("train_count ~d~n", [TrainCount]),
    format("test_count ~d~n", [TestCount]),
    format("correct ~d~n", [Correct]),
    format("accuracy ~6f~n", [Accuracy]).
