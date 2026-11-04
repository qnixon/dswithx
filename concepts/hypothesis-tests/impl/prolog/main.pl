% Exact two-sided permutation test for a difference in means, using
% SWI-Prolog and the libraries that come with it.
%
% If compost made no difference, the "compost" and "control" labels are
% arbitrary, and any 8 of the 16 plants could have carried the compost
% label. We try every one of those splits and count how many give a
% difference at least as large as the one we observed. That fraction is
% the p-value.

:- initialization(main, main).

% read_plants(+Path, -Control, -Compost): the grams of each group, in file
% order, with each column found by its header name.
read_plants(Path, Control, Compost) :-
    read_file_to_string(Path, Text, []),
    split_string(Text, "\n", "", [HeaderLine|Lines]),
    split_string(HeaderLine, ",", "", Header),
    nth0(G, Header, "group"),
    nth0(X, Header, "grams"),
    findall(Group-Grams,
            ( member(Line, Lines),
              Line \== "",
              split_string(Line, ",", "", Fields),
              nth0(G, Fields, Group),
              nth0(X, Fields, GramsText),
              number_string(Grams, GramsText) ),
            Rows),
    findall(Grams, member("control"-Grams, Rows), Control),
    findall(Grams, member("compost"-Grams, Rows), Compost).

% chosen_total(+K, +Plants, -Total): Total is the grams of K of the Plants.
% On backtracking it gives every way to choose them, once each: the first
% plant is either chosen (add it, and choose K - 1 from the rest) or not
% (choose all K from the rest).
chosen_total(0, _, 0).
chosen_total(K, [Plant|Rest], Total) :-
    K > 0,
    K1 is K - 1,
    chosen_total(K1, Rest, Total0),
    Total is Total0 + Plant.
chosen_total(K, [_|Rest], Total) :-
    K > 0,
    chosen_total(K, Rest, Total).

% difference(+N, +Plants, +All, -Difference): one split's chosen total
% minus the rest, for each split in turn.
difference(N, Plants, All, Difference) :-
    chosen_total(N, Plants, Chosen),
    Difference is Chosen - (All - Chosen).

main :-
    current_prolog_flag(argv, [Path|_]),
    read_plants(Path, Control, Compost),
    length(Control, ControlCount),
    length(Compost, N),
    append(Control, Compost, Plants),
    sum_list(Control, ControlTotal),
    sum_list(Compost, CompostTotal),
    All is ControlTotal + CompostTotal,
    % Both groups have N plants, so comparing totals is the same as
    % comparing means, and integer totals stay whole numbers: no
    % floating-point near-ties.
    Observed is CompostTotal - ControlTotal,
    % aggregate_all(count, Goal, Count) counts the ways Goal succeeds.
    aggregate_all(count, difference(N, Plants, All, _), Splits),
    % Two-sided: a difference counts in either direction.
    aggregate_all(count,
                  ( difference(N, Plants, All, D), abs(D) >= abs(Observed) ),
                  AsExtreme),
    % / of two integers gives a float, or an integer when it divides
    % exactly (3232 / 8 is 404); ~6f prints either with six decimals.
    ControlMean is ControlTotal / ControlCount,
    CompostMean is CompostTotal / N,
    ObservedMean is Observed / N,
    PValue is AsExtreme / Splits,
    format("control_count ~d~n", [ControlCount]),
    format("compost_count ~d~n", [N]),
    format("control_mean ~6f~n", [ControlMean]),
    format("compost_mean ~6f~n", [CompostMean]),
    format("observed_difference ~6f~n", [ObservedMean]),
    format("splits ~d~n", [Splits]),
    format("as_extreme ~d~n", [AsExtreme]),
    format("p_value ~6f~n", [PValue]).
