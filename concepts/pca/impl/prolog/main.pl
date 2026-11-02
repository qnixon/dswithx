% Principal component analysis by power iteration, using SWI-Prolog and the
% libraries that come with it.
%
% Standardizes the four scores, builds their correlation matrix, and finds
% the top two eigenvectors (the principal components): power iteration
% finds the first, then deflation removes it from the matrix so the same
% steps find the second. A vector is a list of numbers and a matrix is a
% list of rows.

:- initialization(main, main).

% transpose/2, which turns rows into columns, comes from library(clpfd).
:- use_module(library(clpfd), [transpose/2]).

subjects(["math", "physics", "reading", "writing"]).
steps(1000).

% read_rows(+Path, +Names, -Rows): one list of numbers per line, taking the
% columns called Names in that order.
read_rows(Path, Names, Rows) :-
    read_file_to_string(Path, Text, []),
    split_string(Text, "\n", "", [HeaderLine|Lines]),
    split_string(HeaderLine, ",", "", Header),
    findall(Row,
            ( member(Line, Lines),
              Line \== "",
              split_string(Line, ",", "", Fields),
              maplist([Name, Value]>>( nth0(I, Header, Name),
                                       nth0(I, Fields, Field),
                                       number_string(Value, Field) ),
                      Names, Row) ),
            Rows).

dot(U, V, Dot) :-
    foldl([A, B, Acc0, Acc]>>(Acc is Acc0 + A * B), U, V, 0, Dot).

% mat_vec(+M, +V, -MV): each entry is one row's dot product with V.
mat_vec(M, V, MV) :-
    maplist([Row, X]>>dot(Row, V, X), M, MV).

normalize(V, Unit) :-
    dot(V, V, Squared),
    Length is sqrt(Squared),
    maplist([X, Y]>>(Y is X / Length), V, Unit).

% power(+K, +M, +V, -Final): Final is V after K steps of v <- Mv / |Mv|.
% Each step builds a new list; the recursive call comes last, so Prolog
% reuses the same stack frame.
power(0, _, V, V) :- !.
power(K, M, V, Final) :-
    mat_vec(M, V, MV),
    normalize(MV, Next),
    K1 is K - 1,
    power(K1, M, Next, Final).

% top_eigenvector(+M, -Value, -Vector): start from (1, 0, 0, 0), iterate,
% and make the first entry positive, since -v is an eigenvector too.
top_eigenvector(M, Value, Vector) :-
    length(M, K),
    K0 is K - 1,
    length(Zeros, K0),
    maplist(=(0.0), Zeros),
    steps(Steps),
    power(Steps, M, [1.0|Zeros], V),
    (   V = [First|_], First < 0
    ->  maplist([X, Y]>>(Y is -X), V, Vector)
    ;   Vector = V
    ),
    mat_vec(M, Vector, MV),
    dot(Vector, MV, Value).

% standardize(+Column, -Zs): mean 0 and (sample) standard deviation 1.
standardize(Column, Zs) :-
    length(Column, N),
    sum_list(Column, Sum),
    Mean is Sum / N,
    foldl([X, Acc0, Acc]>>(Acc is Acc0 + (X - Mean) ** 2), Column, 0, Squares),
    SD is sqrt(Squares / (N - 1)),
    maplist([X, Z]>>(Z is (X - Mean) / SD), Column, Zs).

print_component(C, Names, Value, Vector) :-
    length(Names, K),
    format("eigenvalue_~d ~6f~n", [C, Value]),
    % Standardized columns each have variance 1, so the total is K.
    Explained is Value / K,
    format("explained_~d ~6f~n", [C, Explained]),
    forall(nth1(I, Names, Name),
           ( nth1(I, Vector, Loading),
             format("pc~d_~s ~6f~n", [C, Name, Loading]) )).

main :-
    current_prolog_flag(argv, [Path|_]),
    subjects(Names),
    read_rows(Path, Names, Rows),
    length(Rows, N),
    transpose(Rows, Columns),
    maplist(standardize, Columns, ZColumns),
    % The correlation matrix: entry (i, j) is the dot product of
    % standardized columns i and j, divided by n - 1.
    findall(CorrRow,
            ( member(Zi, ZColumns),
              maplist([Zj, R]>>(dot(Zi, Zj, D), R is D / (N - 1)),
                      ZColumns, CorrRow) ),
            Corr),
    top_eigenvector(Corr, Value1, PC1),
    % Deflation: subtract Value1 * v v^T, leaving the rest.
    maplist([Row, Vi, DRow]>>
                maplist([Mij, Vj, D]>>(D is Mij - Value1 * Vi * Vj),
                        Row, PC1, DRow),
            Corr, PC1, Deflated),
    top_eigenvector(Deflated, Value2, PC2),
    format("count ~d~n", [N]),
    print_component(1, Names, Value1, PC1),
    print_component(2, Names, Value2, PC2),
    % The first student's row of standardized scores.
    transpose(ZColumns, [Student1|_]),
    dot(Student1, PC1, Score1),
    dot(Student1, PC2, Score2),
    format("student_1_pc1 ~6f~n", [Score1]),
    format("student_1_pc2 ~6f~n", [Score2]).
