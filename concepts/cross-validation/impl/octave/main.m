% 5-fold cross-validation for k-nearest neighbors, using only core GNU Octave.
%
% Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
% holding out one fold at a time, picks the k with the best average accuracy,
% and then scores that k once on the untouched test seeds. Core Octave has no
% cross-validation or kNN function, and the Octave Forge statistics package
% isn't installed.

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

% How many of the query seeds (q_len, q_wid, q_variety) the K nearest
% training seeds (t_len, t_wid, t_variety) label correctly.
function correct = count_correct(q_len, q_wid, q_variety, t_len, t_wid, t_variety, K)
  correct = 0;
  for t = 1:numel(q_len)
    % Distances from this seed to every training seed at once.
    d = sqrt((t_len - q_len(t)) .^ 2 + (t_wid - q_wid(t)) .^ 2);
    % sort is stable, so equal distances keep file order.
    [~, order] = sort(d);
    nearest = t_variety(order(1:K));
    % Count how many of the nearest share each one's variety. max returns the
    % first position of the largest count, so a tie goes to the nearer seed.
    votes = zeros(K, 1);
    for i = 1:K
      votes(i) = sum(strcmp(nearest, nearest{i}));
    end
    [~, best] = max(votes);
    correct = correct + strcmp(nearest{best}, q_variety{t});
  end
end

FOLDS = 5;
KS = 1:2:15;  % odd k only, so two varieties can't tie

args = argv();
len = str2double(read_column(args{1}, "length_mm"));
wid = str2double(read_column(args{1}, "width_mm"));
variety = read_column(args{1}, "variety");
split_name = read_column(args{1}, "split");

% strcmp compares a whole cell array with one string, giving a logical mask.
is_train = strcmp(split_name, "train");
train_len = len(is_train);
train_wid = wid(is_train);
train_variety = variety(is_train);
test_len = len(~is_train);
test_wid = wid(~is_train);
test_variety = variety(~is_train);
n = numel(train_len);
fold_size = n / FOLDS;

printf("train_count %d\n", n);
printf("test_count %d\n", numel(test_len));
best_k = 0;
best_accuracy = -1;
for K = KS
  correct = 0;
  for f = 1:FOLDS
    % A logical mask marks fold f, one block of fold_size rows. The rows are
    % already shuffled, so consecutive blocks make fair folds.
    held = false(n, 1);
    held((f - 1) * fold_size + 1 : f * fold_size) = true;
    correct = correct + count_correct( ...
      train_len(held), train_wid(held), train_variety(held), ...
      train_len(~held), train_wid(~held), train_variety(~held), K);
  end
  accuracy = correct / n;
  printf("cv_accuracy_k%d %.6f\n", K, accuracy);
  if accuracy > best_accuracy  % strictly better, so ties keep the smaller k
    best_k = K;
    best_accuracy = accuracy;
  end
end

% Only now touch the test seeds, once, with the chosen k and all of train.
correct = count_correct(test_len, test_wid, test_variety, ...
                        train_len, train_wid, train_variety, best_k);
printf("best_k %d\n", best_k);
printf("test_correct %d\n", correct);
printf("test_accuracy %.6f\n", correct / numel(test_len));
