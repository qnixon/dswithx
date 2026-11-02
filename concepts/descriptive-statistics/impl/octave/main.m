% Descriptive statistics on one CSV column, using only core GNU Octave.
%
% Octave works on whole arrays: sum(values) adds every element, and
% values - mean_value subtracts from each one. It also has mean, median, var, and
% std, but those are the method itself, so we write each one out.

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
values = sort(read_column(args{1}, "minutes"));

n = numel(values);
total = sum(values);
mean_value = total / n;

% Arrays count from 1: for n = 120 the middle pair is positions 60 and 61.
if mod(n, 2) == 1
  median_value = values((n + 1) / 2);
else
  median_value = (values(n / 2) + values(n / 2 + 1)) / 2;
end

% Sample variance divides by n - 1, not n (Bessel's correction). The .^
% squares each element; plain ^ would mean a matrix power.
variance = sum((values - mean_value) .^ 2) / (n - 1);

printf("count %d\n", n);
printf("sum %.6f\n", total);
printf("mean %.6f\n", mean_value);
printf("median %.6f\n", median_value);
printf("min %.6f\n", values(1));
printf("max %.6f\n", values(end));
printf("range %.6f\n", values(end) - values(1));
printf("variance %.6f\n", variance);
printf("std_dev %.6f\n", sqrt(variance));
