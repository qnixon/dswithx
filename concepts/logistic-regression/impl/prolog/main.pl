% Logistic regression by gradient descent, using SWI-Prolog and the
% libraries that come with it.
%
% Predicts whether a student passed from study hours and sleep. Each
% feature is rescaled with the training rows' mean and standard deviation,
% then the weights start at zero and take 1,000 steps of batch gradient
% descent on the average log-loss. A Prolog variable takes one value and
% keeps it, so a step can't change the weights: step/4 relates one list of
% weights to the next.

:- initialization(main, main).

% transpose/2, which turns rows into columns, comes from library(clpfd).
:- use_module(library(clpfd), [transpose/2]).

learning_rate(0.5).
steps(1000).

% read_rows(+Path, -Train, -Test): each list holds one Features-Label pair
% per row, such as [1.0, 7.8]-0, split by the "split" column.
read_rows(Path, Train, Test) :-
    read_file_to_string(Path, Text, []),
    split_string(Text, "\n", "", [HeaderLine|Lines]),
    split_string(HeaderLine, ",", "", Header),
    nth0(H, Header, "hours"),
    nth0(S, Header, "sleep"),
    nth0(P, Header, "passed"),
    nth0(G, Header, "split"),
    findall(Split-([Hours, Sleep]-Passed),
            ( member(Line, Lines),
              Line \== "",
              split_string(Line, ",", "", Fields),
              nth0(H, Fields, HoursText), number_string(Hours, HoursText),
              nth0(S, Fields, SleepText), number_string(Sleep, SleepText),
              nth0(P, Fields, PassedText), number_string(Passed, PassedText),
              nth0(G, Fields, Split) ),
            Rows),
    % "train" is a string; findall keeps only the rows that match it.
    findall(Row, member("train"-Row, Rows), Train),
    findall(Row, member("test"-Row, Rows), Test).

dot(U, V, Dot) :-
    foldl([A, B, Acc0, Acc]>>(Acc is Acc0 + A * B), U, V, 0, Dot).

sigmoid(Z, P) :-
    P is 1 / (1 + exp(-Z)).

% mean_sd(+Column, -Mean-SD): the mean and sample standard deviation.
mean_sd(Column, Mean-SD) :-
    length(Column, N),
    sum_list(Column, Sum),
    Mean is Sum / N,
    foldl([X, Acc0, Acc]>>(Acc is Acc0 + (X - Mean) ** 2), Column, 0, Squares),
    SD is sqrt(Squares / (N - 1)).

% scale(+Stats, +Features, -Inputs): rescale each feature, and put a 1 in
% front to multiply the intercept.
scale(Stats, Features, [1.0|Scaled]) :-
    maplist([X, Mean-SD, Z]>>(Z is (X - Mean) / SD), Features, Stats, Scaled).

probability(Weights, Inputs, P) :-
    dot(Weights, Inputs, Z),
    sigmoid(Z, P).

% step(+Xs, +Ys, +Weights, -Next): one step of gradient descent. Every
% error comes from the old weights before any weight moves. Each weight's
% gradient is the mean of (p - y) times its input, a dot product of the
% errors with one column of inputs.
step(Xs, Ys, Weights, Next) :-
    maplist([X, Y, E]>>(probability(Weights, X, P), E is P - Y), Xs, Ys, Errors),
    length(Xs, N),
    transpose(Xs, Columns),
    learning_rate(Rate),
    maplist([W, Column, W1]>>(dot(Errors, Column, G), W1 is W - Rate * G / N),
            Weights, Columns, Next).

% descend(+K, +Xs, +Ys, +Weights, -Final): Final is Weights after K steps.
% The recursive call comes last, so Prolog reuses the same stack frame.
descend(0, _, _, Weights, Weights) :- !.
descend(K, Xs, Ys, Weights, Final) :-
    step(Xs, Ys, Weights, Next),
    K1 is K - 1,
    descend(K1, Xs, Ys, Next, Final).

log_loss_term(P, Y, Loss) :-
    Loss is -(Y * log(P) + (1 - Y) * log(1 - P)).

main :-
    current_prolog_flag(argv, [Path|_]),
    read_rows(Path, Train, Test),
    pairs_keys_values(Train, Features, Ys),
    transpose(Features, FeatureColumns),
    maplist(mean_sd, FeatureColumns, Stats),
    maplist(scale(Stats), Features, Xs),
    length(Xs, N),
    steps(Steps),
    descend(Steps, Xs, Ys, [0.0, 0.0, 0.0], Weights),
    maplist(probability(Weights), Xs, Ps),
    maplist(log_loss_term, Ps, Ys, Losses),
    sum_list(Losses, TotalLoss),
    LogLoss is TotalLoss / N,
    % Count the test rows whose prediction (pass when p >= 0.5) is right.
    aggregate_all(count,
                  ( member(F-Y, Test),
                    scale(Stats, F, X),
                    probability(Weights, X, P),
                    ( P >= 0.5 -> Y =:= 1 ; Y =:= 0 ) ),
                  Correct),
    length(Test, TestCount),
    Accuracy is Correct / TestCount,
    Weights = [Intercept, Hours, Sleep],
    format("train_count ~d~n", [N]),
    format("test_count ~d~n", [TestCount]),
    format("intercept ~6f~n", [Intercept]),
    format("weight_hours ~6f~n", [Hours]),
    format("weight_sleep ~6f~n", [Sleep]),
    format("log_loss ~6f~n", [LogLoss]),
    format("correct ~d~n", [Correct]),
    format("accuracy ~6f~n", [Accuracy]).
