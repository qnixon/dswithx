% Evaluation metrics for a binary classifier, using SWI-Prolog and the
% libraries that come with it.
%
% Reads each part's true label and the model's score, then reports the
% confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
% the accuracy of never flagging anything, and the area under the ROC curve.

:- initialization(main, main).

% read_parts(+Path, -Parts): every part as Defective-Score, in file order,
% with each column found by its header name. Defective is 1 or 0.
read_parts(Path, Parts) :-
    read_file_to_string(Path, Text, []),
    split_string(Text, "\n", "", [HeaderLine|Lines]),
    split_string(HeaderLine, ",", "", Header),
    nth0(D, Header, "defective"),
    nth0(S, Header, "score"),
    findall(Defective-Score,
            ( member(Line, Lines),
              Line \== "",
              split_string(Line, ",", "", Fields),
              nth0(D, Fields, DefectiveText),
              nth0(S, Fields, ScoreText),
              number_string(Defective, DefectiveText),
              number_string(Score, ScoreText) ),
            Parts).

% outcome(+Threshold, +Part, -Outcome): which cell of the confusion matrix
% a part lands in. A part is flagged when its score reaches the threshold.
outcome(Threshold, 1-Score, tp) :- Score >= Threshold.
outcome(Threshold, 0-Score, fp) :- Score >= Threshold.
outcome(Threshold, 1-Score, fn) :- Score < Threshold.
outcome(Threshold, 0-Score, tn) :- Score < Threshold.

% report(+Parts, +Suffix, +Threshold): print the confusion matrix and the
% metrics built from it.
report(Parts, Suffix, Threshold) :-
    % aggregate_all(count, Goal, Count) counts the ways Goal succeeds.
    aggregate_all(count, (member(P, Parts), outcome(Threshold, P, tp)), TP),
    aggregate_all(count, (member(P, Parts), outcome(Threshold, P, fp)), FP),
    aggregate_all(count, (member(P, Parts), outcome(Threshold, P, fn)), FN),
    aggregate_all(count, (member(P, Parts), outcome(Threshold, P, tn)), TN),
    length(Parts, N),
    Accuracy is (TP + TN) / N,
    Precision is TP / (TP + FP),   % of the flagged parts, how many are defective
    Recall is TP / (TP + FN),      % of the defective parts, how many are flagged
    F1 is 2 * Precision * Recall / (Precision + Recall),
    format("tp_at_~w ~d~n", [Suffix, TP]),
    format("fp_at_~w ~d~n", [Suffix, FP]),
    format("fn_at_~w ~d~n", [Suffix, FN]),
    format("tn_at_~w ~d~n", [Suffix, TN]),
    format("accuracy_at_~w ~6f~n", [Suffix, Accuracy]),
    format("precision_at_~w ~6f~n", [Suffix, Precision]),
    format("recall_at_~w ~6f~n", [Suffix, Recall]),
    format("f1_at_~w ~6f~n", [Suffix, F1]).

% pair_points(+Defective, +Good, -Points): 2 when the defective part
% scores higher, 1 for an exact tie, and 0 otherwise.
pair_points(D, G, 2) :- D > G.
pair_points(D, G, 1) :- D =:= G.
pair_points(D, G, 0) :- D < G.

% auc(+Parts, -AUC): the chance that a random defective part outscores a
% random good one. Every pair scores 2 for a win and 1 for a tie, so the
% count stays a whole number until the final division.
auc(Parts, AUC) :-
    findall(S, member(1-S, Parts), Defective),
    findall(S, member(0-S, Parts), Good),
    aggregate_all(sum(Points),
                  ( member(D, Defective), member(G, Good),
                    pair_points(D, G, Points) ),
                  Total),
    length(Defective, P),
    length(Good, N),
    AUC is Total / (2 * P * N).

main :-
    current_prolog_flag(argv, [Path|_]),
    read_parts(Path, Parts),
    length(Parts, N),
    aggregate_all(count, member(1-_, Parts), Defective),
    format("parts ~d~n", [N]),
    format("defective ~d~n", [Defective]),
    % Never flagging anything is right about every good part.
    % / of two integers gives a float, or an integer when it divides
    % exactly; ~6f prints either with six decimals.
    Baseline is (N - Defective) / N,
    format("baseline_accuracy ~6f~n", [Baseline]),
    report(Parts, "50", 0.5),
    report(Parts, "30", 0.3),
    auc(Parts, AUC),
    format("auc ~6f~n", [AUC]).
