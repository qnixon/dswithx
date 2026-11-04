% 5-fold cross-validation for k-nearest neighbors, using SWI-Prolog and the
% libraries that come with it.
%
% Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
% holding out one fold at a time, picks the k with the best accuracy, and
% then scores that k once on the untouched test seeds.

:- initialization(main, main).

folds(5).

% read_seeds(+Path, -Train, -Test): every row as seed(Length, Width,
% Variety), split by its "split" column, the same as on the kNN page.
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
    findall(Seed, member("train"-Seed, Rows), Train),
    findall(Seed, member("test"-Seed, Rows), Test).

% distance_pair(+Seed, +TrainSeed, -Pair): Pair is Distance-Variety.
distance_pair(seed(L1, W1, _), seed(L2, W2, Variety), Distance-Variety) :-
    Distance is sqrt((L1 - L2) ** 2 + (W1 - W2) ** 2).

% nearest(+K, +Train, +Seed, -Varieties): the varieties of the K nearest
% training seeds. keysort is stable, so equal distances keep file order,
% and a list of length K that append finds at the front is the first K.
nearest(K, Train, Seed, Varieties) :-
    maplist(distance_pair(Seed), Train, Pairs),
    keysort(Pairs, Sorted),
    length(Nearest, K),
    append(Nearest, _, Sorted),
    pairs_values(Nearest, Varieties).

% majority(+Labels, -Winner): the label with the most votes.
majority(Labels, Winner) :-
    sort(Labels, Candidates),
    findall(Count-Label,
            ( member(Label, Candidates),
              aggregate_all(count, member(Label, Labels), Count) ),
            Counts),
    max_member(_-Winner, Counts).

% count_correct(+K, +Train, +Seeds, -Correct): how many of Seeds the K
% nearest training seeds label correctly. When the vote and the seed's own
% variety differ, == fails, and aggregate_all doesn't count that seed.
count_correct(K, Train, Seeds, Correct) :-
    aggregate_all(count,
                  ( member(Seed, Seeds),
                    Seed = seed(_, _, Variety),
                    nearest(K, Train, Seed, Labels),
                    majority(Labels, Predicted),
                    Predicted == Variety ),
                  Correct).

% fold(+Train, +F, -HeldOut, -Rest): fold F (from 0) is the block of Size
% rows after the first F * Size. Each append splits a list in two, with
% the length of the first part fixed beforehand.
fold(Train, F, HeldOut, Rest) :-
    folds(Folds),
    length(Train, N),
    Size is N // Folds,
    Start is F * Size,
    length(Before, Start),
    append(Before, Tail, Train),
    length(HeldOut, Size),
    append(HeldOut, After, Tail),
    append(Before, After, Rest).

% cv_accuracy(+Train, +K, -Accuracy): correct across all folds over N.
cv_accuracy(Train, K, Accuracy) :-
    folds(Folds),
    Last is Folds - 1,
    findall(Correct,
            ( between(0, Last, F),
              fold(Train, F, HeldOut, Rest),
              count_correct(K, Rest, HeldOut, Correct) ),
            PerFold),
    sum_list(PerFold, Total),
    length(Train, N),
    Accuracy is Total / N.

% best(+Pairs, -BestK): Pairs are K-Accuracy in increasing K. A later K
% replaces the best only when strictly better, so ties keep the smaller K.
best([K-A|Rest], BestK) :- best(Rest, K, A, BestK).
best([], K, _, K).
best([K-A|Rest], _, BestA, BestK) :-
    A > BestA, !,
    best(Rest, K, A, BestK).
best([_|Rest], K0, A0, BestK) :-
    best(Rest, K0, A0, BestK).

main :-
    current_prolog_flag(argv, [Path|_]),
    read_seeds(Path, Train, Test),
    length(Train, TrainCount),
    length(Test, TestCount),
    format("train_count ~d~n", [TrainCount]),
    format("test_count ~d~n", [TestCount]),
    % Odd K only, so two varieties can't tie.
    findall(K-Accuracy,
            ( between(1, 15, K), K mod 2 =:= 1,
              cv_accuracy(Train, K, Accuracy) ),
            Scores),
    forall(member(K-Accuracy, Scores),
           format("cv_accuracy_k~d ~6f~n", [K, Accuracy])),
    best(Scores, BestK),
    % Only now touch the test seeds, once, with all of the training seeds.
    count_correct(BestK, Train, Test, Correct),
    TestAccuracy is Correct / TestCount,
    format("best_k ~d~n", [BestK]),
    format("test_correct ~d~n", [Correct]),
    format("test_accuracy ~6f~n", [TestAccuracy]).
