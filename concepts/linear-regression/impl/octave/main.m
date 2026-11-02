% Simple linear regression by least squares, using only core GNU Octave.
%
% Fits score = intercept + slope * hours. Octave could do it in one call,
% with polyfit(x, y, 1) or the backslash solve [ones(n, 1) x] \ y, and corr
% gives r; the sums are written out instead.

% The named column of a CSV file, as a column vector of numbers.
function values = read_column(path, name)
  lines = strsplit(strtrim(fileread(path)), "\n");
  header = strsplit(strtrim(lines{1}), ",");
  index = find(strcmp(header, name));
  if isempty(index)
    error("no column %s", name);
  end
  values = zeros(numel(lines) - 1, 1);
  for row = 2:numel(lines)
    fields = strsplit(strtrim(lines{row}), ",");
    values(row - 1) = str2double(fields{index});
  end
end

args = argv();
x = read_column(args{1}, "hours");
y = read_column(args{1}, "score");

n = numel(x);
mean_x = sum(x) / n;
mean_y = sum(y) / n;

% Sums of squared deviations and of cross-products. x - mean_x is the whole
% column of deviations; .* and .^ work element by element, while plain * and
% ^ would be matrix operations.
sxx = sum((x - mean_x) .^ 2);
syy = sum((y - mean_y) .^ 2);
sxy = sum((x - mean_x) .* (y - mean_y));

slope = sxy / sxx;
intercept = mean_y - slope * mean_x;
r = sxy / sqrt(sxx * syy);

printf("count %d\n", n);
printf("slope %.6f\n", slope);
printf("intercept %.6f\n", intercept);
printf("r %.6f\n", r);
printf("r_squared %.6f\n", r ^ 2);
