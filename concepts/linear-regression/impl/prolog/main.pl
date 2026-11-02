% Simple linear regression by least squares, using SWI-Prolog and the
% libraries that come with it.
%
% Fits score = intercept + slope * hours. A rule such as
% deviation(Mean, X, D) is true when D is X - Mean, and running the
% program asks Prolog to find values that make main true. There's no
% mean, regression, or correlation built in, so we state each one.

:- initialization(main, main).

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

% mean(+Values, -Mean): the sum divided by the count.
mean(Values, Mean) :-
    sum_list(Values, Sum),
    length(Values, N),
    Mean is Sum / N.

% deviation(+Mean, +X, -D): D is X - Mean. "is" does the arithmetic;
% D = X - Mean would only build the term X - Mean.
deviation(Mean, X, D) :-
    D is X - Mean.

% product(+A, +B, -P): P is A times B.
product(A, B, P) :-
    P is A * B.

% sum_of_products(+As, +Bs, -Sum): multiply the lists element by element
% and add up the results. maplist with two input lists walks them side by
% side, so the first hours value meets the first score, and so on.
sum_of_products(As, Bs, Sum) :-
    maplist(product, As, Bs, Products),
    sum_list(Products, Sum).

main :-
    current_prolog_flag(argv, [Path|_]),
    read_column(Path, "hours", Xs),
    read_column(Path, "score", Ys),
    length(Xs, N),
    % First pass: the means.
    mean(Xs, MeanX),
    mean(Ys, MeanY),
    % Second pass: each value's deviation from its mean.
    maplist(deviation(MeanX), Xs, Dxs),
    maplist(deviation(MeanY), Ys, Dys),
    sum_of_products(Dxs, Dxs, Sxx),
    sum_of_products(Dys, Dys, Syy),
    sum_of_products(Dxs, Dys, Sxy),
    Slope is Sxy / Sxx,
    Intercept is MeanY - Slope * MeanX,
    R is Sxy / sqrt(Sxx * Syy),
    RSquared is R * R,
    format("count ~d~n", [N]),
    forall(member(Label-Number,
                  [slope-Slope, intercept-Intercept, r-R,
                   r_squared-RSquared]),
           format("~w ~6f~n", [Label, Number])).
