% Train and test error for polynomials of degree 1 to 8, using only core GNU
% Octave.
%
% Each polynomial is fitted by least squares to the training drives only:
% we build the normal equations and solve them by Gaussian elimination. Then
% we measure its root-mean-square error on the training drives and on the
% test drives it never saw. Octave could fit each one with polyfit, or solve
% the equations with backslash, A \ b; the elimination is written out instead.

MAX_DEGREE = 8;

% Solve A x = b by Gaussian elimination with partial pivoting.
function x = solve(A, b)
  n = numel(b);
  M = [A, b];  % the augmented matrix: b becomes column n + 1
  for col = 1:n
    % Swap up the row with the largest entry in this column, which keeps the
    % rounding error small. max returns the value and its position, counted
    % from the top of the slice, so add col - 1 to get the row.
    [~, offset] = max(abs(M(col:n, col)));
    pivot = col + offset - 1;
    M([col, pivot], :) = M([pivot, col], :);
    for r = col + 1:n
      factor = M(r, col) / M(col, col);
      M(r, col:end) -= factor * M(col, col:end);
    end
  end
  % Back substitution, from the last unknown up. M(r, r + 1:n) is a row and
  % x(r + 1:n) a column, so * is their dot product.
  x = zeros(n, 1);
  for r = n:-1:1
    x(r) = (M(r, n + 1) - M(r, r + 1:n) * x(r + 1:n)) / M(r, r);
  end
end

% Row i of the result is 1, z_i, z_i^2, ..., z_i^degree. z is a column and
% 0:degree a row, so .^ broadcasts them into a matrix.
function P = powers(z, degree)
  P = z .^ (0:degree);
end

function e = rmse(coefs, z, y)
  predicted = powers(z, numel(coefs) - 1) * coefs;
  e = sqrt(sum((predicted - y) .^ 2) / numel(y));
end

args = argv();
lines = strsplit(strtrim(fileread(args{1})), "\n");
header = strsplit(strtrim(lines{1}), ",");
speed_col = find(strcmp(header, "speed"));
litres_col = find(strcmp(header, "litres"));
split_col = find(strcmp(header, "split"));
n = numel(lines) - 1;
speed = zeros(n, 1);
litres = zeros(n, 1);
is_train = false(n, 1);
for row = 1:n
  fields = strsplit(strtrim(lines{row + 1}), ",");
  speed(row) = str2double(fields{speed_col});
  litres(row) = str2double(fields{litres_col});
  is_train(row) = strcmp(fields{split_col}, "train");
end

% A logical vector picks out the rows where it is true.
x_train = speed(is_train);
y_train = litres(is_train);
x_test = speed(!is_train);
y_test = litres(!is_train);

% Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
% largest entry at degree 8) would swamp the small ones and make the
% equations hard to solve accurately.
low = min(x_train);
high = max(x_train);
mid = (low + high) / 2;
half = (high - low) / 2;
z_train = (x_train - mid) / half;
z_test = (x_test - mid) / half;

printf("train_count %d\n", numel(y_train));
printf("test_count %d\n", numel(y_test));
train_errors = zeros(MAX_DEGREE, 1);
test_errors = zeros(MAX_DEGREE, 1);
for degree = 1:MAX_DEGREE
  % Least squares: the coefficients c solve (P' P) c = P' y. Entry (i, j) of
  % P' P is the sum of z^(i + j), and entry i of P' y the sum of y z^i.
  P = powers(z_train, degree);
  coefs = solve(P' * P, P' * y_train);
  train_errors(degree) = rmse(coefs, z_train, y_train);
  test_errors(degree) = rmse(coefs, z_test, y_test);
end
for degree = 1:MAX_DEGREE
  printf("train_rmse_d%d %.6f\n", degree, train_errors(degree));
end
for degree = 1:MAX_DEGREE
  printf("test_rmse_d%d %.6f\n", degree, test_errors(degree));
end
