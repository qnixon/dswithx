% Logistic regression by gradient descent, using only core GNU Octave.
%
% Predicts whether a student passed from study hours and sleep. Each feature
% is rescaled with the training rows' mean and standard deviation, then the
% weights start at zero and take STEPS fixed steps of batch gradient descent
% on the average log-loss. The training rows form a matrix X, so each step is
% two matrix products.

LEARNING_RATE = 0.5;
STEPS = 1000;

% The named column of a CSV file, as a cell array of text fields.
function fields = read_column(path, name)
  lines = strsplit(strtrim(fileread(path)), "\n");
  header = strsplit(strtrim(lines{1}), ",");
  index = find(strcmp(header, name));
  if isempty(index)
    error("no column %s", name);
  end
  fields = cell(numel(lines) - 1, 1);
  for row = 2:numel(lines)
    parts = strsplit(strtrim(lines{row}), ",");
    fields{row - 1} = parts{index};
  end
end

% The ./ divides element by element, so this works on a whole vector of z.
function p = sigmoid(z)
  p = 1 ./ (1 + exp(-z));
end

args = argv();
path = args{1};
% str2double turns a whole cell array of text into a column of numbers.
features = [str2double(read_column(path, "hours")), ...
            str2double(read_column(path, "sleep"))];
passed = str2double(read_column(path, "passed"));
is_train = strcmp(read_column(path, "split"), "train");

y = passed(is_train);
n = numel(y);

% Scale each feature to mean 0 and (sample) standard deviation 1, using the
% training rows only. sum(A, 1) adds down each column; subtracting the 1-by-2
% row of means from an n-by-2 matrix subtracts it from every row.
train_features = features(is_train, :);
means = sum(train_features, 1) / n;
sds = sqrt(sum((train_features - means) .^ 2, 1) / (n - 1));
% The column of ones multiplies the intercept.
scale = @(f) [ones(rows(f), 1), (f - means) ./ sds];

X = scale(train_features);
weights = zeros(3, 1);
for step = 1:STEPS
  % Gradient of the average log-loss: X' * (p - y) / n, where X' is the
  % transpose. The whole gradient is computed before any weight changes.
  errors = sigmoid(X * weights) - y;
  weights = weights - LEARNING_RATE * (X' * errors) / n;
end

p = sigmoid(X * weights);
log_loss = -sum(y .* log(p) + (1 - y) .* log(1 - p)) / n;

predicted = sigmoid(scale(features(~is_train, :)) * weights) >= 0.5;
actual = passed(~is_train) == 1;
test_count = numel(actual);
correct = sum(predicted == actual);

printf("train_count %d\n", n);
printf("test_count %d\n", test_count);
printf("intercept %.6f\n", weights(1));
printf("weight_hours %.6f\n", weights(2));
printf("weight_sleep %.6f\n", weights(3));
printf("log_loss %.6f\n", log_loss);
printf("correct %d\n", correct);
printf("accuracy %.6f\n", correct / test_count);
