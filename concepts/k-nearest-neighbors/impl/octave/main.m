% k-nearest neighbors classification, using only core GNU Octave.
%
% Each test seed is labelled with the majority variety among its K nearest
% training seeds, by Euclidean distance. Core Octave has no kNN function, and
% the Octave Forge statistics package isn't installed.

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

K = 5;
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

correct = 0;
for t = 1:numel(test_len)
  % Distances from this test seed to all 150 training seeds at once.
  d = sqrt((train_len - test_len(t)) .^ 2 + (train_wid - test_wid(t)) .^ 2);
  % sort returns the sorted values and their original positions. It's
  % stable, so equal distances keep file order.
  [~, order] = sort(d);
  nearest = train_variety(order(1:K));
  % Count how many of the nearest share each one's variety. max returns the
  % first position of the largest count, so a tie goes to the nearer seed.
  votes = zeros(K, 1);
  for i = 1:K
    votes(i) = sum(strcmp(nearest, nearest{i}));
  end
  [~, best] = max(votes);
  correct = correct + strcmp(nearest{best}, test_variety{t});
end

printf("train_count %d\n", numel(train_len));
printf("test_count %d\n", numel(test_len));
printf("correct %d\n", correct);
printf("accuracy %.6f\n", correct / numel(test_len));
