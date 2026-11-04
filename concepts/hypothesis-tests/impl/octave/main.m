% Exact two-sided permutation test for a difference in means, using only
% core GNU Octave.
%
% If compost made no difference, the "compost" and "control" labels are
% arbitrary, and any n of the plants could have carried the compost label.
% We try every one of those splits and count how many give a difference at
% least as large as the one we observed. That fraction is the p-value.

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

args = argv();
group = read_column(args{1}, "group");
grams = str2double(read_column(args{1}, "grams"));

% strcmp compares a whole cell array with one string, giving a logical mask.
control = grams(strcmp(group, "control"));
compost = grams(strcmp(group, "compost"));
n = numel(compost);
plants = [control; compost];
total = sum(plants);

% Both groups have n plants, so comparing totals is the same as comparing
% means, and totals stay whole numbers: no floating-point near-ties.
observed = sum(compost) - sum(control);

% nchoosek with a vector returns every choice of n positions, one per row.
% Indexing plants with that matrix gives a matrix of grams the same shape,
% and sum(..., 2) totals each row: one relabeled compost total per split.
chosen = nchoosek(1:numel(plants), n);
relabeled = sum(plants(chosen), 2);
difference = relabeled - (total - relabeled);
splits = rows(chosen);
as_extreme = sum(abs(difference) >= abs(observed));  % two-sided

printf("control_count %d\n", numel(control));
printf("compost_count %d\n", n);
printf("control_mean %.6f\n", mean(control));
printf("compost_mean %.6f\n", mean(compost));
printf("observed_difference %.6f\n", observed / n);
printf("splits %d\n", splits);
printf("as_extreme %d\n", as_extreme);
printf("p_value %.6f\n", as_extreme / splits);
