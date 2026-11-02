% Principal component analysis by power iteration, using only core GNU Octave.
%
% Standardizes the four scores, builds their correlation matrix, and finds the
% top two eigenvectors (the principal components): power iteration finds the
% first, then deflation removes it from the matrix so the same steps find the
% second. Octave has eig and svd, but those are the method itself, so we
% write the iteration out.

SUBJECTS = {"math", "physics", "reading", "writing"};
STEPS = 1000;

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

% Power iteration: multiply by the matrix and rescale, steps times.
function [value, v] = top_eigenvector(M, steps)
  v = [1; zeros(rows(M) - 1, 1)];
  for step = 1:steps
    w = M * v;
    v = w / norm(w);  % norm is the vector's length, sqrt(w' * w)
  end
  % An eigenvector can point either way; make its first entry positive.
  if v(1) < 0
    v = -v;
  end
  value = v' * M * v;
end

args = argv();
% One row per student, one column per subject.
X = zeros(0, 0);
for s = 1:numel(SUBJECTS)
  X(:, s) = read_column(args{1}, SUBJECTS{s});
end
[n, k] = size(X);

% Standardize each column to mean 0 and (sample) standard deviation 1.
% sum(X, 1) adds down each column, and subtracting the 1-by-k row of means
% subtracts it from every row.
means = sum(X, 1) / n;
sds = sqrt(sum((X - means) .^ 2, 1) / (n - 1));
Z = (X - means) ./ sds;

% The correlation matrix: the covariance of the standardized columns.
corr_matrix = Z' * Z / (n - 1);

[value_1, pc_1] = top_eigenvector(corr_matrix, STEPS);
% Deflation: subtract the first component's share, leaving the rest.
% pc_1 * pc_1' is a column times a row, the 4-by-4 outer product.
[value_2, pc_2] = top_eigenvector(corr_matrix - value_1 * (pc_1 * pc_1'), STEPS);

printf("count %d\n", n);
values = [value_1, value_2];
pcs = [pc_1, pc_2];
for c = 1:2
  printf("eigenvalue_%d %.6f\n", c, values(c));
  % Standardized columns each have variance 1, so the total is k.
  printf("explained_%d %.6f\n", c, values(c) / k);
  for s = 1:k
    printf("pc%d_%s %.6f\n", c, SUBJECTS{s}, pcs(s, c));
  end
end
printf("student_1_pc1 %.6f\n", Z(1, :) * pc_1);
printf("student_1_pc2 %.6f\n", Z(1, :) * pc_2);
