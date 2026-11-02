% k-nearest neighbors classification, using SWI-Prolog and the libraries
% that come with it.
%
% Each test seed is labelled with the majority variety among its K nearest
% training seeds, by Euclidean distance. A rule such as
% classify(Train, Seed, Variety) is true when Variety is the vote of Seed's
% neighbors, and running the program asks Prolog to find values that make
% main true.

:- initialization(main, main).

k(5).

% read_seeds(+Path, -Train, -Test): every row as seed(Length, Width,
% Variety), split by its "split" column. findall collects every term that
% satisfies the goals in the middle, one per line. nth0 finds a column's
% position by its header name, or picks the field at that position.
read_seeds(Path, Train, Test) :-
    read_file_to_string(Path, Text, []),
    split_string(Text, "\n", "", [HeaderLine|Lines]),
    split_string(HeaderLine, ",", "", Header),
    nth0(L, Header, "length_mm"),
    nth0(W, Header, "width_mm"),
    nth0(V, Header, "variety"),
    nth0(S, Header, "split"),
    findall(Split-seed(Length, Width, Variety),
            ( member(Line, Lines),
              Line \== "",
              split_string(Line, ",", "", Fields),
              nth0(L, Fields, LengthText),
              nth0(W, Fields, WidthText),
              nth0(V, Fields, Variety),
              nth0(S, Fields, Split),
              number_string(Length, LengthText),
              number_string(Width, WidthText) ),
            Rows),
    % Only rows whose key unifies with "train" (or "test") are collected.
    findall(Seed, member("train"-Seed, Rows), Train),
    findall(Seed, member("test"-Seed, Rows), Test).

% distance_pair(+Seed, +TrainSeed, -Pair): Pair is Distance-Variety, the
% Key-Value form that keysort orders by key. "is" does the arithmetic.
distance_pair(seed(L1, W1, _), seed(L2, W2, Variety), Distance-Variety) :-
    Distance is sqrt((L1 - L2) ** 2 + (W1 - W2) ** 2).

% nearest(+Train, +Seed, -Varieties): the varieties of the K training seeds
% closest to Seed. keysort is stable and keeps repeated keys, so seeds at
% exactly equal distances stay in file order. (sort/2 would drop pairs
% that are entirely equal.) append(Nearest, _, Sorted) holds when Nearest
% is the start of Sorted, and fixing its length at K takes the first K.
nearest(Train, Seed, Varieties) :-
    maplist(distance_pair(Seed), Train, Pairs),
    keysort(Pairs, Sorted),
    k(K),
    length(Nearest, K),
    append(Nearest, _, Sorted),
    pairs_values(Nearest, Varieties).

% majority(+Labels, -Winner): the label with the most votes. sort/2 drops
% repeats, which here is what we want: one entry per variety. aggregate_all
% counts the solutions of member(Label, Labels), that is, how many times
% Label appears. max_member picks the largest Count-Label pair; with two
% varieties and an odd K, two counts can never be equal.
majority(Labels, Winner) :-
    sort(Labels, Candidates),
    findall(Count-Label,
            ( member(Label, Candidates),
              aggregate_all(count, member(Label, Labels), Count) ),
            Counts),
    max_member(_-Winner, Counts).

% classify(+Train, +Seed, -Variety): the variety Seed's neighbors vote for.
classify(Train, Seed, Variety) :-
    nearest(Train, Seed, Labels),
    majority(Labels, Variety).

% correct(+Train, +Seed): true when the vote matches Seed's own variety.
% When it doesn't, == fails, so the goal fails, and aggregate_all below
% simply doesn't count that seed.
correct(Train, Seed) :-
    Seed = seed(_, _, Variety),
    classify(Train, Seed, Predicted),
    Predicted == Variety.

main :-
    current_prolog_flag(argv, [Path|_]),
    read_seeds(Path, Train, Test),
    length(Train, TrainCount),
    length(Test, TestCount),
    aggregate_all(count, ( member(Seed, Test), correct(Train, Seed) ), Correct),
    Accuracy is Correct / TestCount,
    format("train_count ~d~n", [TrainCount]),
    format("test_count ~d~n", [TestCount]),
    format("correct ~d~n", [Correct]),
    format("accuracy ~6f~n", [Accuracy]).
