% k-means clustering (Lloyd's algorithm), using SWI-Prolog and the
% libraries that come with it.
%
% Starts from the first K points as centroids, then alternates two steps
% until no point changes cluster: assign each point to its nearest
% centroid, and move each centroid to the mean of its points. Prolog has
% no loops, so the repetition is a rule, run/7, that calls itself with the
% moved centroids.

:- initialization(main, main).

k(3).
max_iterations(100).

% read_column(+Path, +Name, -Values): Values are the numbers in the column
% called Name. findall collects every Value that satisfies the goals in
% the middle, one per line.
read_column(Path, Name, Values) :-
    read_file_to_string(Path, Text, []),
    split_string(Text, "\n", "", [HeaderLine|Lines]),
    split_string(HeaderLine, ",", "", Header),
    nth0(Index, Header, Name),
    findall(Value,
            ( member(Line, Lines),
              Line \== "",
              split_string(Line, ",", "", Fields),
              nth0(Index, Fields, Field),
              number_string(Value, Field) ),
            Values).

% A point is the term X-Y. The - only joins the two numbers into a pair;
% it subtracts nothing, because only "is" does arithmetic.

% squared_distance(+P, +Q, -D): D is the squared Euclidean distance. It
% ranks centroids in the same order as the distance, so no sqrt is needed.
squared_distance(X1-Y1, X2-Y2, D) :-
    D is (X1 - X2) ** 2 + (Y1 - Y2) ** 2.

% nearest(+Centroids, +Point, -J): J is the number of the closest
% centroid, counting from 1. aggregate_all(min(D, I), Goal, min(_, J))
% finds the smallest D over every solution of Goal and the I that went
% with it. nth1 tries the centroids in order, and when several share the
% smallest D, aggregate_all keeps the first: a tie goes to the lower index.
nearest(Centroids, Point, J) :-
    aggregate_all(min(D, I),
                  ( nth1(I, Centroids, C),
                    squared_distance(Point, C, D) ),
                  min(_, J)).

% mean(+Values, -Mean)
mean(Values, Mean) :-
    sum_list(Values, Sum),
    length(Values, N),
    Mean is Sum / N.

% update(+Points, +Assignment, +Centroids, -Moved): Moved holds each
% centroid moved to the mean of its points. pairs_keys_values joins each
% point to its cluster number, as J-(X-Y).
update(Points, Assignment, Centroids, Moved) :-
    pairs_keys_values(Labeled, Assignment, Points),
    findall(New,
            ( nth1(J, Centroids, Old),
              findall(P, member(J-P, Labeled), Members),
              move(Members, Old, New) ),
            Moved).

% move(+Members, +Old, -New): an empty cluster keeps its old centroid.
move([], Old, Old).
move([P|Ps], _, X-Y) :-
    pairs_keys_values([P|Ps], Xs, Ys),
    mean(Xs, X),
    mean(Ys, Y).

% run(+Points, +Done, +Previous, +Centroids, -Iterations, -Assignment,
%     -Final): one assignment step, then either stop or update and go
% again. Done counts the steps so far. Previous is the last assignment, or
% the atom none before the first pass, so the first comparison always
% counts as a change. == asks whether two terms are identical, so it
% compares the whole assignment list at once.
run(Points, Done, Previous, Centroids, Iterations, Assignment, Final) :-
    Step is Done + 1,
    maplist(nearest(Centroids), Points, New),
    (   New == Previous
    ->  Iterations = Step, Assignment = New, Final = Centroids
    ;   update(Points, New, Centroids, Moved),
        (   max_iterations(Step)
        ->  Iterations = Step, Assignment = New, Final = Moved
        ;   run(Points, Step, New, Moved, Iterations, Assignment, Final)
        )
    ).

% point_inertia(+Centroids, +Point, +J, -D): the squared distance from
% Point to its centroid, number J.
point_inertia(Centroids, Point, J, D) :-
    nth1(J, Centroids, C),
    squared_distance(Point, C, D).

main :-
    current_prolog_flag(argv, [Path|_]),
    read_column(Path, "x", Xs),
    read_column(Path, "y", Ys),
    pairs_keys_values(Points, Xs, Ys),
    k(K),
    length(Start, K),
    append(Start, _, Points),
    run(Points, 0, none, Start, Iterations, Assignment, Centroids),
    maplist(point_inertia(Centroids), Points, Assignment, Squares),
    sum_list(Squares, Inertia),
    format("iterations ~d~n", [Iterations]),
    forall(nth1(J, Centroids, X-Y),
           format("centroid_~d_x ~6f~ncentroid_~d_y ~6f~n", [J, X, J, Y])),
    % aggregate_all(count, ...) counts the solutions of a goal: here, the
    % positions in Assignment that hold J.
    forall(between(1, K, J),
           ( aggregate_all(count, member(J, Assignment), Size),
             format("size_~d ~d~n", [J, Size]) )),
    format("inertia ~6f~n", [Inertia]).
