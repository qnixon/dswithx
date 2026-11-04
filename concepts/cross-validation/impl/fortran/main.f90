! 5-fold cross-validation for k-nearest neighbors, using only standard
! Fortran.
!
! Splits the training seeds into 5 folds, scores each odd k from 1 to 15 by
! holding out one fold at a time, picks the k with the best average accuracy,
! and then scores that k once on the untouched test seeds.

program cross_validation
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  integer, parameter :: folds = 5

  ! A derived type groups a seed's measurements with its variety.
  type :: seed
    real(dp) :: point(2)
    character(len=16) :: variety
  end type seed

  type(seed), allocatable :: train(:), test(:)
  integer :: k, best_k, correct
  real(dp) :: accuracy, best_accuracy
  character(len=20) :: name

  call read_seeds(train, test)

  print "(a, 1x, i0)", "train_count", size(train)
  print "(a, 1x, i0)", "test_count", size(test)
  best_accuracy = -1
  do k = 1, 15, 2   ! odd k only, so two varieties can't tie
    accuracy = cv_accuracy(k)
    write(name, "(a, i0)") "cv_accuracy_k", k   ! build the label as text
    call say(trim(name), accuracy)
    if (accuracy > best_accuracy) then   ! strictly better: ties keep smaller k
      best_k = k
      best_accuracy = accuracy
    end if
  end do

  ! Only now touch the test seeds, once, with the chosen k and all of train.
  correct = count_correct(test, train, best_k)
  print "(a, 1x, i0)", "best_k", best_k
  print "(a, 1x, i0)", "test_correct", correct
  call say("test_accuracy", real(correct, dp) / size(test))

contains

  real(dp) function cv_accuracy(k)
    integer, intent(in) :: k
    integer :: f, fold_size, first, last, correct

    ! Fold f is rows first to last, one block of fold_size. The rows are
    ! already shuffled, so consecutive blocks make fair folds.
    fold_size = size(train) / folds
    correct = 0
    do f = 1, folds
      first = (f - 1) * fold_size + 1
      last = f * fold_size
      ! train(first:last) is an array section, the held-out fold. The array
      ! constructor [ ... ] joins the sections before and after it into the
      ! other four folds; an empty section such as train(1:0) adds nothing.
      correct = correct + count_correct(train(first:last), &
        [train(:first - 1), train(last + 1:)], k)
    end do
    cv_accuracy = real(correct, dp) / size(train)
  end function cv_accuracy

  ! How many of points the k nearest of reference seeds label correctly.
  integer function count_correct(points, reference, k)
    type(seed), intent(in) :: points(:), reference(:)
    integer, intent(in) :: k
    integer :: i

    count_correct = 0
    do i = 1, size(points)
      if (classify(points(i)%point, reference, k) == points(i)%variety) &
        count_correct = count_correct + 1
    end do
  end function count_correct

  function classify(point, reference, k) result(variety)
    real(dp), intent(in) :: point(2)
    type(seed), intent(in) :: reference(:)
    integer, intent(in) :: k
    character(len=16) :: variety
    character(len=16) :: nearest(k)
    real(dp) :: distance(size(reference))
    logical :: taken(size(reference))
    integer :: votes(k), i, j

    ! norm2 is the Euclidean length of a vector, so this is the distance.
    do i = 1, size(reference)
      distance(i) = norm2(point - reference(i)%point)
    end do

    ! Take the closest untaken seed k times. minloc returns the first of
    ! equal minimums, so equal distances keep file order, like a stable sort.
    taken = .false.
    do i = 1, k
      j = minloc(distance, dim=1, mask=.not. taken)
      taken(j) = .true.
      nearest(i) = reference(j)%variety
    end do

    ! Each neighbor's vote total; maxloc also returns the first maximum, so
    ! a tied vote goes to the variety seen first among the nearest.
    do i = 1, k
      votes(i) = count(nearest == nearest(i))
    end do
    variety = nearest(maxloc(votes, dim=1))
  end function classify

  subroutine read_seeds(train, test)
    type(seed), allocatable, intent(out) :: train(:), test(:)
    character(len=256) :: path, line, text
    integer :: unit, status, length_col, width_col, variety_col, split_col
    type(seed) :: s

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") line
    length_col = field_index(line, "length_mm")
    width_col = field_index(line, "width_mm")
    variety_col = field_index(line, "variety")
    split_col = field_index(line, "split")
    allocate(train(0), test(0))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      ! An internal read parses a number. It must read from a variable,
      ! not straight from the result of field(), so we copy into text.
      text = field(line, length_col)
      read(text, *) s%point(1)
      text = field(line, width_col)
      read(text, *) s%point(2)
      s%variety = field(line, variety_col)
      if (field(line, split_col) == "train") then
        train = [train, s]   ! grows the array by one
      else
        test = [test, s]
      end if
    end do
    close(unit)
  end subroutine read_seeds

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

end program cross_validation
