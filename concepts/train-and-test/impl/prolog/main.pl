% Train and test error for polynomials of degree 1 to 8, using SWI-Prolog
% and the libraries that come with it.
%
% Each polynomial is fitted by least squares to the training drives only:
% we build the normal equations and solve them by Gaussian elimination.
% Then we measure its root-mean-square error on the training drives and on
% the test drives it never saw. A matrix is a list of rows.

:- initialization(main, main).

max_degree(8).

% read_drives(+Path, -Drives): every drive as Split-Speed-Litres, in file
% order, with each column found by its header name.
read_drives(Path, Drives) :-
    read_file_to_string(Path, Text, []),
    split_string(Text, "\n", "", [HeaderLine|Lines]),
    split_string(HeaderLine, ",", "", Header),
    nth0(S, Header, "speed"),
    nth0(L, Header, "litres"),
    nth0(P, Header, "split"),
    findall(Split-Speed-Litres,
            ( member(Line, Lines),
              Line \== "",
              split_string(Line, ",", "", Fields),
              nth0(S, Fields, SpeedText),
              nth0(L, Fields, LitresText),
              nth0(P, Fields, Split),
              number_string(Speed, SpeedText),
              number_string(Litres, LitresText) ),
            Drives).

dot(U, V, Dot) :-
    foldl([A, B, Acc0, Acc]>>(Acc is Acc0 + A * B), U, V, 0, Dot).

% solve(+A, +B, -X): solve A x = B by Gaussian elimination with partial
% pivoting. Each row of the augmented matrix is a row of A with its entry
% of B on the end.
solve(A, B, X) :-
    maplist([Row, V, Aug]>>append(Row, [V], Aug), A, B, Augmented),
    eliminate(Augmented, Triangle),
    back_substitute(Triangle, X).

% eliminate(+Rows, -Triangle): take out the row with the largest first
% entry, which keeps the rounding error small, and subtract a multiple of
% it from every other row so their first entries become 0. Those rows,
% without their first column, are a smaller system of the same kind, so we
% recurse. Each row of the triangle is one entry shorter than the last.
eliminate([], []).
eliminate([First|Rest], [Pivot|Triangle]) :-
    foldl(larger_leading, Rest, First, Pivot),
    selectchk(Pivot, [First|Rest], Others),
    Pivot = [P|PivotRest],
    maplist(reduce(P, PivotRest), Others, Reduced),
    eliminate(Reduced, Triangle).

% larger_leading(+Row, +Best0, -Best): keep whichever row has the larger
% first entry, ignoring sign.
larger_leading(Row, Best0, Best) :-
    Row = [A|_],
    Best0 = [B|_],
    (   abs(A) > abs(B)
    ->  Best = Row
    ;   Best = Best0
    ).

% reduce(+P, +PivotRest, +Row, -Reduced): Row minus Factor times the pivot
% row, dropping the first column, which is now 0.
reduce(P, PivotRest, [R|RowRest], Reduced) :-
    Factor is R / P,
    maplist([PC, RC, NC]>>(NC is RC - Factor * PC), PivotRest, RowRest, Reduced).

% back_substitute(+Triangle, -X): from the last unknown up. Each row is
% [Coefficient, entries for the later unknowns ..., right-hand side].
back_substitute([], []).
back_substitute([[C|Rest]|Rows], [X|Later]) :-
    back_substitute(Rows, Later),
    append(Entries, [Rhs], Rest),
    dot(Entries, Later, Known),
    X is (Rhs - Known) / C.

% fit(+Points, +Degree, -Coefs): least squares. The coefficients solve
% (Z^T Z) c = Z^T y, where row i of Z is 1, z_i, z_i^2, ..., z_i^Degree.
% Points holds Z-Y pairs.
fit(Points, Degree, Coefs) :-
    numlist(0, Degree, Powers),
    findall(Row,
            ( member(I, Powers),
              findall(Sum,
                      ( member(J, Powers),
                        aggregate_all(sum(Z ** (I + J)), member(Z-_, Points), Sum) ),
                      Row) ),
            A),
    findall(Sum,
            ( member(I, Powers),
              aggregate_all(sum(Y * Z ** I), member(Z-Y, Points), Sum) ),
            B),
    solve(A, B, Coefs).

% predict(+Coefs, +Z, -Y): c0 + c1 z + c2 z^2 + ...
predict(Coefs, Z, Y) :-
    length(Coefs, N),
    N1 is N - 1,
    numlist(0, N1, Powers),
    foldl([C, I, Acc0, Acc]>>(Acc is Acc0 + C * Z ** I), Coefs, Powers, 0, Y).

rmse(Coefs, Points, RMSE) :-
    aggregate_all(sum((P - Y) ** 2),
                  ( member(Z-Y, Points), predict(Coefs, Z, P) ),
                  Total),
    length(Points, N),
    RMSE is sqrt(Total / N).

main :-
    current_prolog_flag(argv, [Path|_]),
    read_drives(Path, Drives),
    findall(X-Y, member("train"-X-Y, Drives), Train),
    findall(X-Y, member("test"-X-Y, Drives), Test),
    % Map the training speeds onto -1 to 1. Raw speeds to the 16th power
    % (the largest entry at degree 8) would swamp the small ones and make
    % the equations hard to solve accurately. The speeds are integers, so
    % float/1 makes each z a float rather than an integer or a fraction.
    findall(X, member(X-_, Train), Speeds),
    min_list(Speeds, Low),
    max_list(Speeds, High),
    Mid is (Low + High) / 2,
    Half is (High - Low) / 2,
    Scale = [X-Y, Z-Y]>>(Z is float((X - Mid) / Half)),
    maplist(Scale, Train, TrainZ),
    maplist(Scale, Test, TestZ),
    length(Train, NTrain),
    length(Test, NTest),
    format("train_count ~d~n", [NTrain]),
    format("test_count ~d~n", [NTest]),
    max_degree(Max),
    numlist(1, Max, Degrees),
    maplist(fit(TrainZ), Degrees, Fits),
    forall(nth1(D, Fits, Coefs),
           ( rmse(Coefs, TrainZ, E), format("train_rmse_d~d ~6f~n", [D, E]) )),
    forall(nth1(D, Fits, Coefs),
           ( rmse(Coefs, TestZ, E), format("test_rmse_d~d ~6f~n", [D, E]) )).
