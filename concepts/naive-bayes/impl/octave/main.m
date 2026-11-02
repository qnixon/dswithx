% Categorical naive Bayes with add-one (Laplace) smoothing, using only core
% GNU Octave.
%
% Learns P(label) and P(feature value | label) by counting training rows, then
% labels each test row with the label that has the highest log-probability.
% Counting is done with logical masks: strcmp compares a whole column of
% strings at once, and sum counts the matches.

% The named column of a CSV file, as a column cell array of strings.
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

FEATURES = {"has_link", "mentions_money", "known_sender"};

args = argv();
split = read_column(args{1}, "split");
is_train = strcmp(split, "train");  % a logical vector, one entry per row
is_test = strcmp(split, "test");
label = read_column(args{1}, "label");
train_label = label(is_train);
test_label = label(is_test);
n_train = numel(train_label);
n_test = numel(test_label);

% unique returns the distinct labels sorted, so they are tried in
% alphabetical order.
labels = unique(train_label);

% Each feature column, split into its training and test rows.
train_values = cell(1, numel(FEATURES));
test_values = cell(1, numel(FEATURES));
for f = 1:numel(FEATURES)
  column = read_column(args{1}, FEATURES{f});
  train_values{f} = column(is_train);
  test_values{f} = column(is_test);
end

% scores(i, c) is the log-probability score of test row i under label c.
scores = zeros(n_test, numel(labels));
for c = 1:numel(labels)
  in_label = strcmp(train_label, labels{c});
  n_c = sum(in_label);
  % Logs turn the product of probabilities into a sum, avoiding underflow.
  scores(:, c) = log(n_c / n_train);
  for f = 1:numel(FEATURES)
    m = numel(unique(train_values{f}));  % distinct values the feature takes
    % For each test row, count the training rows with this label and the
    % same value. cellfun calls the function on every cell and collects
    % the numbers into a vector.
    matches = cellfun(@(v) sum(in_label & strcmp(train_values{f}, v)), ...
                      test_values{f});
    % Add-one smoothing: an unseen value never gets probability zero.
    scores(:, c) += log((matches + 1) / (n_c + m));
  end
end

% max along each row returns the column of the first maximum, so an exact
% tie goes to the alphabetically first label.
[~, best] = max(scores, [], 2);
correct = sum(strcmp(labels(best), test_label));

printf("train_count %d\n", n_train);
printf("test_count %d\n", n_test);
printf("correct %d\n", correct);
printf("accuracy %.6f\n", correct / n_test);
