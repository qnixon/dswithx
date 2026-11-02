% Descriptive statistics on one CSV column, using SWI-Prolog and the
% libraries that come with it.
%
% A Prolog program is facts and rules, not steps. A rule such as
% median(Sorted, Median) is true when Median is the median of Sorted, and
% running the program asks Prolog to find values that make main true.
% There's no mean, median, or variance built in, so we state each one.

:- initialization(main, main).

column("minutes").

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

% median(+Sorted, -Median): the middle value, or the mean of the two
% middle values. nth0 counts from 0: for 120 values, positions 59 and 60.
median(Sorted, Median) :-
    length(Sorted, N),
    Middle is N // 2,
    (   N mod 2 =:= 1
    ->  nth0(Middle, Sorted, Median)
    ;   Before is Middle - 1,
        nth0(Before, Sorted, A),
        nth0(Middle, Sorted, B),
        Median is (A + B) / 2
    ).

% squared_deviation(+Mean, +X, -D): D is (X - Mean) squared. "is" does the
% arithmetic; D = X - Mean would only build the term X - Mean.
squared_deviation(Mean, X, D) :-
    D is (X - Mean) ** 2.

main :-
    current_prolog_flag(argv, [Path|_]),
    column(Name),
    read_column(Path, Name, Unsorted),
    % msort keeps repeated values; sort would drop them.
    msort(Unsorted, Values),
    length(Values, N),
    sum_list(Values, Sum),
    Mean is Sum / N,
    median(Values, Median),
    Values = [Min|_],
    last(Values, Max),
    Range is Max - Min,
    % Sample variance divides by n - 1, not n (Bessel's correction).
    maplist(squared_deviation(Mean), Values, Squares),
    sum_list(Squares, SumOfSquares),
    Variance is SumOfSquares / (N - 1),
    StdDev is sqrt(Variance),
    format("count ~d~n", [N]),
    forall(member(Label-Number,
                  [sum-Sum, mean-Mean, median-Median, min-Min, max-Max,
                   range-Range, variance-Variance, std_dev-StdDev]),
           format("~w ~6f~n", [Label, Number])).
