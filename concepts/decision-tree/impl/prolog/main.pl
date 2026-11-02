% A decision tree classifier (CART with Gini impurity), using SWI-Prolog
% and the libraries that come with it.
%
% Grows a tree on the training days by always making the split that leaves
% the two sides purest, then predicts rain for the test days. Prints the
% tree in preorder: each node is either a split (feature and threshold) or
% a leaf (its prediction).
%
% In Prolog the tree is just a term, a nested piece of data such as
% split(1, 1000.95, leaf(yes), leaf(no)). There's nothing to declare:
% leaf(Rain) and split(Feature, Threshold, Left, Right) are names we pick,
% and a split simply holds two more trees inside it.

:- initialization(main, main).

features([humidity, pressure, wind]).
max_depth(3).
min_size(5).

% read_days(+Path, -Train, -Test): each day is day(Values, Rain), where
% Values are its features in the order of features/1 and Rain is the atom
% yes or no. The header gives each column's position.
read_days(Path, Train, Test) :-
    read_file_to_string(Path, Text, []),
    split_string(Text, "\n", "", [HeaderLine|Lines]),
    split_string(HeaderLine, ",", "", Header),
    features(Names),
    findall(Split-day(Values, Rain),
            ( member(Line, Lines),
              Line \== "",
              split_string(Line, ",", "", Fields),
              maplist(feature_value(Header, Fields), Names, Values),
              field(Header, Fields, rain, Rain),
              field(Header, Fields, split, Split) ),
            Tagged),
    findall(Day, member(train-Day, Tagged), Train),
    findall(Day, member(test-Day, Tagged), Test).

% field(+Header, +Fields, +Name, -Atom): the field in column Name, as an atom.
field(Header, Fields, Name, Atom) :-
    atom_string(Name, Column),
    nth0(Index, Header, Column),
    nth0(Index, Fields, Field),
    atom_string(Atom, Field).

% feature_value(+Header, +Fields, +Name, -Value): the field as a float.
% "54" would read as the integer 54, so float/1 makes every value alike.
feature_value(Header, Fields, Name, Value) :-
    field(Header, Fields, Name, Atom),
    atom_number(Atom, Number),
    Value is float(Number).

rain_of(day(_, Rain), Rain).

% gini(+Labels, -G): the chance that two days drawn at random (with
% replacement) disagree. include/3 keeps the labels equal to yes.
gini(Labels, G) :-
    length(Labels, N),
    include(==(yes), Labels, Yes),
    length(Yes, Rainy),
    P is Rainy / N,
    G is 1 - P * P - (1 - P) * (1 - P).

% majority(+Labels, -Rain): strictly more than half must be rainy to
% predict rain, so an even split predicts no.
majority(Labels, Rain) :-
    length(Labels, N),
    include(==(yes), Labels, Yes),
    length(Yes, Rainy),
    (   2 * Rainy > N -> Rain = yes ; Rain = no ).

% divide(+F, +Threshold, +Days, -Left, -Right): the days at or below the
% threshold, then the days above it.
at_or_below(F, Threshold, day(Values, _)) :-
    nth0(F, Values, X),
    X =< Threshold.

divide(F, Threshold, Days, Left, Right) :-
    partition(at_or_below(F, Threshold), Days, Left, Right).

% score(+Days, +F, +Threshold, -Score): the weighted Gini impurity left
% after splitting at this feature and threshold.
score(Days, F, Threshold, Score) :-
    divide(F, Threshold, Days, Left, Right),
    maplist(rain_of, Left, LeftLabels),
    maplist(rain_of, Right, RightLabels),
    length(Left, NL),
    length(Right, NR),
    gini(LeftLabels, GL),
    gini(RightLabels, GR),
    Score is (NL * GL + NR * GR) / (NL + NR).

% candidate(+Days, -F, -Threshold): true for each candidate split. On
% backtracking it yields features in column order and, for each, the
% midpoints between neighboring distinct values from smallest to largest.
% sort/2 drops repeated values, which is exactly what we want here.
candidate(Days, F, Threshold) :-
    features(Names),
    nth0(F, Names, _),
    findall(X, ( member(day(Values, _), Days), nth0(F, Values, X) ), Xs),
    sort(Xs, Distinct),
    append(_, [A, B|_], Distinct),
    Threshold is (A + B) / 2.

% best_split(+Days, -Best): Best is Score-F-Threshold with the lowest
% score. findall lists every candidate in the order tried; foldl walks the
% list, and only a strictly lower score replaces the best so far, so the
% first split tried wins ties. Fails when there are no candidates.
best_split(Days, Best) :-
    findall(S-F-T, ( candidate(Days, F, T), score(Days, F, T, S) ),
            [First|Rest]),
    foldl(lower, Rest, First, Best).

lower(S-F-T, BestS-_-_, S-F-T) :- S < BestS, !.
lower(_, Best, Best).

% grow(+Days, +Depth, -Tree): Tree is the tree grown from Days, starting
% at depth 0. This is a relation, not a function: grow states what Tree
% is, and the split clause holds when its two children are themselves
% trees grown from each side. The first clause catches every stopping
% rule; the cut (!) commits to it so the split clause isn't tried.
grow(Days, Depth, leaf(Rain)) :-
    maplist(rain_of, Days, Labels),
    majority(Labels, Rain),
    gini(Labels, G),
    length(Days, N),
    min_size(MinSize),
    max_depth(MaxDepth),
    (   G =:= 0
    ;   N < MinSize
    ;   Depth =:= MaxDepth
    ;   \+ ( best_split(Days, S-_-_), S < G )  % no split makes the sides purer
    ),
    !.
grow(Days, Depth, split(F, Threshold, Left, Right)) :-
    best_split(Days, _-F-Threshold),
    divide(F, Threshold, Days, LeftDays, RightDays),
    Next is Depth + 1,
    grow(LeftDays, Next, Left),
    grow(RightDays, Next, Right).

% predict(+Tree, +Values, -Rain): one clause per kind of node, and Prolog
% picks the clause whose head matches the term. Reaching a leaf ends the
% walk; a split asks its question and walks down one side.
predict(leaf(Rain), _, Rain).
predict(split(F, Threshold, Left, Right), Values, Rain) :-
    nth0(F, Values, X),
    (   X =< Threshold
    ->  predict(Left, Values, Rain)
    ;   predict(Right, Values, Rain)
    ).

% preorder(+Tree, -Nodes): every node, then its left side, then its right.
preorder(leaf(Rain), [leaf(Rain)]).
preorder(split(F, T, L, R), [split(F, T, L, R)|Nodes]) :-
    preorder(L, LeftNodes),
    preorder(R, RightNodes),
    append(LeftNodes, RightNodes, Nodes).

is_leaf(leaf(_)).

% describe(+K, +Node): print the output lines for node number K.
describe(K, leaf(Rain)) :-
    format("node_~d_predict ~w~n", [K, Rain]).
describe(K, split(F, Threshold, _, _)) :-
    features(Names),
    nth0(F, Names, Name),
    format("node_~d_feature ~w~n", [K, Name]),
    format("node_~d_threshold ~6f~n", [K, Threshold]).

% count_correct(+Tree, +Days, -Correct): how many days the tree labels
% correctly. The goal inside findall succeeds once per such day.
count_correct(Tree, Days, Correct) :-
    findall(x, ( member(day(Values, Rain), Days),
                 predict(Tree, Values, Rain) ),
            Hits),
    length(Hits, Correct).

main :-
    current_prolog_flag(argv, [Path|_]),
    read_days(Path, Train, Test),
    grow(Train, 0, Tree),
    length(Train, NTrain),
    length(Test, NTest),
    format("train_count ~d~n", [NTrain]),
    format("test_count ~d~n", [NTest]),
    preorder(Tree, Nodes),
    % nth1 numbers the nodes from 1 as forall walks them.
    forall(nth1(K, Nodes, Node), describe(K, Node)),
    include(is_leaf, Nodes, Leaves),
    length(Leaves, NLeaves),
    format("leaves ~d~n", [NLeaves]),
    count_correct(Tree, Train, TrainCorrect),
    count_correct(Tree, Test, Correct),
    TrainAccuracy is TrainCorrect / NTrain,
    Accuracy is Correct / NTest,
    format("train_accuracy ~6f~n", [TrainAccuracy]),
    format("correct ~d~n", [Correct]),
    format("accuracy ~6f~n", [Accuracy]).
