% Principal component analysis with eig, Octave's eigenvalue function.
%
% The built-in version of ../octave/main.m. eig finds every eigenvalue and
% eigenvector of the correlation matrix at once, in place of power
% iteration and deflation.

SUBJECTS = {"math", "physics", "reading", "writing"};

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
% One row per student, one column per subject.
X = zeros(0, 0);
for s = 1:numel(SUBJECTS)
  X(:, s) = read_column(args{1}, SUBJECTS{s});
end
[n, k] = size(X);

% Standardize each column with mean and std (which divides by n - 1).
Z = (X - mean(X)) ./ std(X);

% eig returns the eigenvectors as the columns of V and the eigenvalues on
% the diagonal of D, smallest first, so sort puts the largest first.
[V, D] = eig(corr(X));
[values, order] = sort(diag(D), "descend");
pcs = V(:, order);
% An eigenvector can point either way; make each one's first entry positive.
pcs = pcs .* sign(pcs(1, :));

printf("count %d\n", n);
for c = 1:2
  printf("eigenvalue_%d %.6f\n", c, values(c));
  % Standardized columns each have variance 1, so the total is k.
  printf("explained_%d %.6f\n", c, values(c) / k);
  for s = 1:k
    printf("pc%d_%s %.6f\n", c, SUBJECTS{s}, pcs(s, c));
  end
end
printf("student_1_pc1 %.6f\n", Z(1, :) * pcs(:, 1));
printf("student_1_pc2 %.6f\n", Z(1, :) * pcs(:, 2));
