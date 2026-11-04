% Evaluation metrics for a binary classifier, using only core GNU Octave.
%
% Reads each part's true label and the model's score, then reports the
% confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
% the accuracy of never flagging anything, and the area under the ROC curve.

% The named column of a CSV file, as a column cell array of strings. Wrap it
% in str2double to get numbers.
function values = read_column(path, name)
  lines = strsplit(strtrim(fileread(path)), "\n");
  header = strsplit(strtrim(lines{1}), ",");
  index = find(strcmp(header, name));
  if isempty(index)
    error("no column %s", name);
  end
  values = cell(numel(lines) - 1, 1);
  for row = 2:numel(lines)
    fields = strsplit(strtrim(lines{row}), ",");
    values{row - 1} = fields{index};
  end
end

% Counts and metrics at one threshold. Every comparison below works on the
% whole column at once and gives a logical vector, and sum counts its trues.
function report(defective, score, suffix, threshold)
  flagged = score >= threshold;  % a part is flagged when it reaches the threshold
  tp = sum(flagged & defective);
  fp = sum(flagged & !defective);
  fn = sum(!flagged & defective);
  tn = sum(!flagged & !defective);

  accuracy = (tp + tn) / numel(score);
  precision = tp / (tp + fp);  % of the flagged parts, how many are defective
  recall = tp / (tp + fn);     % of the defective parts, how many are flagged
  f1 = 2 * precision * recall / (precision + recall);

  printf("tp_at_%s %d\n", suffix, tp);
  printf("fp_at_%s %d\n", suffix, fp);
  printf("fn_at_%s %d\n", suffix, fn);
  printf("tn_at_%s %d\n", suffix, tn);
  printf("accuracy_at_%s %.6f\n", suffix, accuracy);
  printf("precision_at_%s %.6f\n", suffix, precision);
  printf("recall_at_%s %.6f\n", suffix, recall);
  printf("f1_at_%s %.6f\n", suffix, f1);
end

args = argv();
defective = strcmp(read_column(args{1}, "defective"), "1");  % logical column
score = str2double(read_column(args{1}, "score"));
n = numel(score);
positives = sum(defective);

printf("parts %d\n", n);
printf("defective %d\n", positives);
% Never flagging anything is right about every good part.
printf("baseline_accuracy %.6f\n", (n - positives) / n);
report(defective, score, "50", 0.5);
report(defective, score, "30", 0.3);

% AUC: the chance that a random defective part outscores a random good one.
% Comparing a column with a row broadcasts: d > g' is a matrix with one row
% per defective part and one column per good part, holding every pairwise
% comparison, and (:) flattens it so sum counts them all. A win scores 2 and
% a tie 1, so the count stays a whole number until the final division.
d = score(defective);
g = score(!defective);
points = 2 * sum((d > g')(:)) + sum((d == g')(:));
printf("auc %.6f\n", points / (2 * numel(d) * numel(g)));
