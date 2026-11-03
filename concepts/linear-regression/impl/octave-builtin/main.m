% Simple linear regression with polyfit, Octave's polynomial fit.
%
% The built-in version of ../octave/main.m. polyfit(x, y, 1) fits a
% straight line, a polynomial of degree 1, and corr gives r.

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

% polyfit returns the coefficients highest power first: slope, then
% intercept.
p = polyfit(x, y, 1);
r = corr(x, y);

printf("count %d\n", numel(x));
printf("slope %.6f\n", p(1));
printf("intercept %.6f\n", p(2));
printf("r %.6f\n", r);
printf("r_squared %.6f\n", r ^ 2);
