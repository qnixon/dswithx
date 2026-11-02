% A decision tree classifier (CART with Gini impurity), using only core GNU
% Octave.
%
% Grows a tree on the training days by always making the split that leaves the
% two sides purest, then predicts rain for the test days. Prints the tree in
% preorder: each node is either a split (feature and threshold) or a leaf
% (its prediction). Core Octave has no tree function, and the Octave Forge
% statistics package isn't installed.

% The named column of a CSV file, as a cell array of strings (one per row).
% str2double turns a numeric column into numbers afterward.
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

% Chance that two days drawn at random (with replacement) disagree, from the
% share p of rainy days. The .^ squares each element, so p can be a whole row
% of shares at once.
function g = gini(p)
  g = 1 - p .^ 2 - (1 - p) .^ 2;
end

% A leaf's prediction. An even split predicts "no".
function node = leaf(rain)
  if sum(rain) > numel(rain) / 2
    node = struct("label", "yes");
  else
    node = struct("label", "no");
  end
end

% The best split of the days in X (one row per day, one column per feature)
% with rain labels in the logical column rain.
function [best_score, best_f, best_threshold] = best_split(X, rain)
  n = rows(X);
  best_score = Inf;
  best_f = 0;
  best_threshold = 0;
  for f = 1:columns(X)
    values = unique(X(:, f));  % unique also sorts, smallest first
    thresholds = (values(1:end-1) + values(2:end))' / 2;  % one row
    % Comparing a column of days with a row of thresholds broadcasts to a
    % table: one row per day, one column per threshold, true where the day
    % goes left. sum adds down each column, so every threshold is scored at
    % once, with no loop over thresholds.
    goes_left = X(:, f) <= thresholds;
    n_left = sum(goes_left);
    yes_left = sum(goes_left & rain);
    n_right = n - n_left;
    yes_right = sum(rain) - yes_left;
    scores = (n_left .* gini(yes_left ./ n_left) ...
              + n_right .* gini(yes_right ./ n_right)) / n;
    % min returns the first position of the smallest score, so the smallest
    % threshold wins a tie; only a strictly lower score replaces an earlier
    % feature's best.
    [score, i] = min(scores);
    if score < best_score
      best_score = score;
      best_f = f;
      best_threshold = thresholds(i);
    end
  end
end

% A node is a struct. A leaf has one field, label; a split has feature,
% threshold, left, and right, and its children are whole structs stored
% inside it. Nesting structs reads like the tree itself and lets grow call
% itself on each side, the way the method is written.
function node = grow(X, rain, depth)
  impurity = gini(sum(rain) / numel(rain));
  if impurity == 0 || numel(rain) < 5 || depth == 3
    node = leaf(rain);
    return;
  end
  [score, f, threshold] = best_split(X, rain);
  if score >= impurity
    node = leaf(rain);  % no split makes the sides purer
    return;
  end
  left = X(:, f) <= threshold;  % logical indexing picks each side's rows
  node.feature = f;
  node.threshold = threshold;
  node.left = grow(X(left, :), rain(left), depth + 1);
  node.right = grow(X(~left, :), rain(~left), depth + 1);
end

function label = predict(node, x)
  while ~isfield(node, "label")
    if x(node.feature) <= node.threshold
      node = node.left;
    else
      node = node.right;
    end
  end
  label = node.label;
end

% Print the tree in preorder. k is this node's number; next is the number
% for whatever comes after its subtree. leaves counts the leaves printed.
function [next, leaves] = show_tree(node, k, names)
  if isfield(node, "label")
    printf("node_%d_predict %s\n", k, node.label);
    next = k + 1;
    leaves = 1;
  else
    printf("node_%d_feature %s\n", k, names{node.feature});
    printf("node_%d_threshold %.6f\n", k, node.threshold);
    [k, left_leaves] = show_tree(node.left, k + 1, names);
    [next, right_leaves] = show_tree(node.right, k, names);
    leaves = left_leaves + right_leaves;
  end
end

% How many days in X the tree labels correctly.
function correct = count_correct(tree, X, rain)
  correct = 0;
  for d = 1:rows(X)
    correct = correct + (strcmp(predict(tree, X(d, :)), "yes") == rain(d));
  end
end

args = argv();
names = {"humidity", "pressure", "wind"};
X = zeros(0, 0);
for f = 1:numel(names)
  X(:, f) = str2double(read_column(args{1}, names{f}));
end
rain = strcmp(read_column(args{1}, "rain"), "yes");  % true or false per day
is_train = strcmp(read_column(args{1}, "split"), "train");

tree = grow(X(is_train, :), rain(is_train), 0);

printf("train_count %d\n", sum(is_train));
printf("test_count %d\n", sum(~is_train));
[~, leaves] = show_tree(tree, 1, names);
printf("leaves %d\n", leaves);

train_correct = count_correct(tree, X(is_train, :), rain(is_train));
correct = count_correct(tree, X(~is_train, :), rain(~is_train));
printf("train_accuracy %.6f\n", train_correct / sum(is_train));
printf("correct %d\n", correct);
printf("accuracy %.6f\n", correct / sum(~is_train));
