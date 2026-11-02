% k-means clustering (Lloyd's algorithm), using only core GNU Octave.
%
% Starts from the first K points as centroids, then alternates two steps until
% no point changes cluster: assign each point to its nearest centroid, and move
% each centroid to the mean of its points. Each point is a row of a 150-by-2
% matrix, so both steps work on every point at once.

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

K = 3;
MAX_ITERATIONS = 100;

args = argv();
points = [read_column(args{1}, "x"), read_column(args{1}, "y")];
n = rows(points);

centroids = points(1:K, :);  % a copy: changing it never changes points
assignment = [];
distances = zeros(n, K);
iterations = 0;
while iterations < MAX_ITERATIONS
  iterations += 1;
  % points - centroids(j, :) subtracts the 1-by-2 row from all 150 rows
  % (broadcasting), and sum(..., 2) adds across each row, giving every
  % point's squared distance to centroid j.
  for j = 1:K
    distances(:, j) = sum((points - centroids(j, :)) .^ 2, 2);
  end
  % The smallest squared distance is also the smallest distance. min with
  % [] and 2 works along each row; its second output is the column of the
  % minimum, the first one on a tie, so ties go to the lower index.
  [~, new_assignment] = min(distances, [], 2);
  if isequal(new_assignment, assignment)
    break;
  end
  assignment = new_assignment;
  for j = 1:K
    members = points(assignment == j, :);  % the rows assigned to j
    if rows(members) > 0  % an empty cluster keeps its old centroid
      centroids(j, :) = sum(members, 1) / rows(members);
    end
  end
end

% Pair each point with its own centroid's row, then add every squared difference.
inertia = sum(sum((points - centroids(assignment, :)) .^ 2));

printf("iterations %d\n", iterations);
for j = 1:K
  printf("centroid_%d_x %.6f\n", j, centroids(j, 1));
  printf("centroid_%d_y %.6f\n", j, centroids(j, 2));
end
for j = 1:K
  printf("size_%d %d\n", j, sum(assignment == j));
end
printf("inertia %.6f\n", inertia);
