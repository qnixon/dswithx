! A decision tree classifier (CART with Gini impurity), using only standard
! Fortran.
!
! Grows a tree on the training days by always making the split that leaves the
! two sides purest, then predicts rain for the test days. Prints the tree in
! preorder: each node is either a split (feature and threshold) or a leaf
! (its prediction).

program decision_tree
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  integer, parameter :: n_features = 3, max_depth = 3, min_size = 5
  integer, parameter :: max_nodes = 2**(max_depth + 1) - 1   ! a full tree
  character(len=*), parameter :: features(n_features) = &
    [character(len=8) :: "humidity", "pressure", "wind"]

  ! The tree is a table of nodes, filled in the order grow creates them,
  ! which is preorder. A leaf has feature 0; a split has its two children.
  type node
    integer :: feature = 0
    real(dp) :: threshold = 0
    integer :: left = 0, right = 0
    logical :: rain = .false.   ! a leaf's prediction
  end type node
  type(node) :: tree(max_nodes)
  integer :: nodes = 0

  real(dp), allocatable :: x(:, :), x_test(:, :)   ! one row per day
  logical, allocatable :: rain(:), rain_test(:)
  integer :: k, i, root, leaves, train_correct, correct

  call read_days(x, rain, x_test, rain_test)
  ! The training days are passed around as a list of row numbers.
  root = grow([(i, i = 1, size(rain))], 0)   ! [(i, i = 1, n)] is 1, 2, ..., n

  print "(a, 1x, i0)", "train_count", size(rain)
  print "(a, 1x, i0)", "test_count", size(rain_test)
  leaves = 0
  do k = 1, nodes
    if (tree(k)%feature == 0) then
      ! merge needs equal-length strings, so "no " has a space that trim drops.
      print "(a, i0, a, 1x, a)", "node_", k, "_predict", &
        trim(merge("yes", "no ", tree(k)%rain))
      leaves = leaves + 1
    else
      print "(a, i0, a, 1x, a)", "node_", k, "_feature", &
        trim(features(tree(k)%feature))
      call say_node(k, tree(k)%threshold)
    end if
  end do
  print "(a, 1x, i0)", "leaves", leaves

  train_correct = count([(predict(x(i, :)) .eqv. rain(i), i = 1, size(rain))])
  correct = count([(predict(x_test(i, :)) .eqv. rain_test(i), &
                    i = 1, size(rain_test))])
  call say("train_accuracy", real(train_correct, dp) / size(rain))
  print "(a, 1x, i0)", "correct", correct
  call say("accuracy", real(correct, dp) / size(rain_test))

contains

  ! Chance that two days drawn at random (with replacement) disagree.
  real(dp) function gini(rows)
    integer, intent(in) :: rows(:)
    real(dp) :: p

    p = real(count(rain(rows)), dp) / size(rows)   ! rain(rows) picks those days
    gini = 1 - p * p - (1 - p) * (1 - p)
  end function gini

  ! An even split predicts "no".
  logical function majority(rows)
    integer, intent(in) :: rows(:)
    majority = count(rain(rows)) > size(rows) / 2.0_dp
  end function majority

  ! The split with the lowest weighted Gini impurity. Features are tried in
  ! column order and thresholds from smallest to largest; only a strictly
  ! lower score replaces the best, so the first of any tie wins.
  subroutine best_split(rows, best_score, best_feature, best_threshold)
    integer, intent(in) :: rows(:)
    real(dp), intent(out) :: best_score, best_threshold
    integer, intent(out) :: best_feature
    real(dp), allocatable :: values(:)
    real(dp) :: threshold, score
    integer :: f, i

    best_score = huge(1.0_dp)   ! the largest double, so any split beats it
    best_feature = 0
    best_threshold = 0
    do f = 1, n_features
      values = sorted_distinct(x(rows, f))
      do i = 1, size(values) - 1
        threshold = (values(i) + values(i + 1)) / 2
        ! pack keeps the rows where the condition holds.
        associate (left => pack(rows, x(rows, f) <= threshold), &
                   right => pack(rows, x(rows, f) > threshold))
          score = (size(left) * gini(left) + size(right) * gini(right)) &
                  / size(rows)
        end associate
        if (score < best_score) then
          best_score = score
          best_feature = f
          best_threshold = threshold
        end if
      end do
    end do
  end subroutine best_split

  ! Add a node for these rows, then its children, and return its number.
  ! Numbering a node before its children is what makes the table preorder.
  recursive integer function grow(rows, depth) result(k)
    integer, intent(in) :: rows(:), depth
    real(dp) :: impurity, score, threshold
    integer :: f, left, right

    nodes = nodes + 1
    k = nodes
    tree(k)%rain = majority(rows)
    impurity = gini(rows)
    if (impurity == 0 .or. size(rows) < min_size .or. depth == max_depth) return
    call best_split(rows, score, f, threshold)
    if (score >= impurity) return   ! no split makes the sides purer
    tree(k)%feature = f
    tree(k)%threshold = threshold
    ! Call grow in two statements so the left subtree is numbered first.
    left = grow(pack(rows, x(rows, f) <= threshold), depth + 1)
    right = grow(pack(rows, x(rows, f) > threshold), depth + 1)
    tree(k)%left = left
    tree(k)%right = right
  end function grow

  ! Walk from the root (node 1) down to a leaf.
  logical function predict(day)
    real(dp), intent(in) :: day(:)
    integer :: k

    k = root
    do while (tree(k)%feature /= 0)
      if (day(tree(k)%feature) <= tree(k)%threshold) then
        k = tree(k)%left
      else
        k = tree(k)%right
      end if
    end do
    predict = tree(k)%rain
  end function predict

  ! The distinct values of a column, smallest first (an insertion sort that
  ! skips repeats).
  function sorted_distinct(column) result(values)
    real(dp), intent(in) :: column(:)
    real(dp), allocatable :: values(:)
    integer :: i, j

    allocate(values(0))
    do i = 1, size(column)
      if (any(values == column(i))) cycle
      j = count(values < column(i))   ! how many go before it
      values = [values(:j), column(i), values(j + 1:)]
    end do
  end function sorted_distinct

  ! Read the CSV into training and test days, sorted by the "split" column.
  subroutine read_days(x, rain, x_test, rain_test)
    real(dp), allocatable, intent(out) :: x(:, :), x_test(:, :)
    logical, allocatable, intent(out) :: rain(:), rain_test(:)
    character(len=256) :: path, header, line, text
    integer :: unit, status, cols(n_features), c_rain, c_split, j
    real(dp) :: day(n_features)

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") header
    do j = 1, n_features
      cols(j) = field_index(header, trim(features(j)))
    end do
    c_rain = field_index(header, "rain")
    c_split = field_index(header, "split")
    allocate(x(0, n_features), rain(0), x_test(0, n_features), rain_test(0))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      do j = 1, n_features
        text = field(line, cols(j))
        read(text, *) day(j)   ! an internal read parses the number
      end do
      if (field(line, c_split) == "train") then
        call append(x, rain, day, field(line, c_rain) == "yes")
      else
        call append(x_test, rain_test, day, field(line, c_rain) == "yes")
      end if
    end do
    close(unit)
  end subroutine read_days

  ! Add one day to a matrix and its label to a vector. Fortran stores
  ! matrices column by column, so we rebuild the matrix one row longer.
  subroutine append(x, rain, day, is_rain)
    real(dp), allocatable, intent(inout) :: x(:, :)
    logical, allocatable, intent(inout) :: rain(:)
    real(dp), intent(in) :: day(:)
    logical, intent(in) :: is_rain
    real(dp), allocatable :: grown(:, :)

    allocate(grown(size(x, 1) + 1, size(x, 2)))
    grown(:size(x, 1), :) = x
    grown(size(x, 1) + 1, :) = day
    call move_alloc(grown, x)   ! x takes grown's storage
    rain = [rain, is_rain]      ! grows the vector by one
  end subroutine append

  ! The position of a name in a comma-separated header line.
  integer function field_index(header, name)
    character(len=*), intent(in) :: header, name
    integer :: i, fields

    fields = 1
    do i = 1, len_trim(header)
      if (header(i:i) == ",") fields = fields + 1
    end do
    do field_index = 1, fields
      if (field(header, field_index) == name) return
    end do
    error stop "column not found: " // name
  end function field_index

  ! The k-th comma-separated field of a line.
  function field(line, k) result(text)
    character(len=*), intent(in) :: line
    integer, intent(in) :: k
    character(len=:), allocatable :: text
    integer :: start, i, comma

    start = 1
    do i = 1, k - 1
      start = start + index(line(start:), ",")
    end do
    comma = index(line(start:), ",")
    if (comma == 0) then
      text = trim(line(start:))
    else
      text = line(start:start + comma - 2)
    end if
  end function field

  subroutine say_node(k, threshold)
    integer, intent(in) :: k
    real(dp), intent(in) :: threshold
    character(len=24) :: name

    write(name, "(a, i0, a)") "node_", k, "_threshold"
    call say(trim(name), threshold)
  end subroutine say_node

  ! Print "name value" with six decimals. The f0.6 format drops the zero
  ! before the point (0.5 prints as .500000), so we put it back.
  subroutine say(name, x)
    character(len=*), intent(in) :: name
    real(dp), intent(in) :: x
    character(len=40) :: text

    write(text, "(f0.6)") x
    if (text(1:1) == ".") text = "0" // text
    if (text(1:2) == "-.") text = "-0" // text(2:)
    print "(a, 1x, a)", name, trim(text)
  end subroutine say

end program decision_tree
