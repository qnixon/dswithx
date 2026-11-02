! Logistic regression by gradient descent, using only standard Fortran.
!
! Predicts whether a student passed from study hours and sleep. Each feature is
! rescaled with the training rows' mean and standard deviation, then the weights
! start at zero and take STEPS fixed steps of batch gradient descent on the
! average log-loss.

program logistic_regression
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  real(dp), parameter :: learning_rate = 0.5_dp
  integer, parameter :: steps = 1000
  ! Each row of x is [1, hours, sleep]; the leading 1 multiplies the intercept.
  real(dp), allocatable :: x(:, :), x_test(:, :), y(:), y_test(:), p(:)
  real(dp) :: means(2), sds(2), weights(3), log_loss
  integer :: n, step, j, correct

  call read_rows(x, y, x_test, y_test)
  n = size(y)

  ! Scale each feature to mean 0 and (sample) standard deviation 1, using the
  ! training rows only. Column j + 1 holds feature j (column 1 is the ones).
  do j = 1, 2
    means(j) = sum(x(:, j + 1)) / n
    sds(j) = sqrt(sum((x(:, j + 1) - means(j))**2) / (n - 1))
    x(:, j + 1) = (x(:, j + 1) - means(j)) / sds(j)
    x_test(:, j + 1) = (x_test(:, j + 1) - means(j)) / sds(j)
  end do

  weights = 0
  do step = 1, steps
    ! matmul(x, weights) is every row's score at once. The whole gradient,
    ! the mean of (p - y) times each input, is found before any weight moves.
    p = sigmoid(matmul(x, weights))
    weights = weights - learning_rate * matmul(transpose(x), p - y) / n
  end do

  p = sigmoid(matmul(x, weights))
  log_loss = -sum(y * log(p) + (1 - y) * log(1 - p)) / n
  ! merge(a, b, mask) picks a where mask is true: here, the predicted label.
  ! nint rounds the 0.0 and 1.0 labels to integers for an exact comparison.
  correct = count(merge(1, 0, sigmoid(matmul(x_test, weights)) >= 0.5_dp) &
                  == nint(y_test))

  print "(a, 1x, i0)", "train_count", n
  print "(a, 1x, i0)", "test_count", size(y_test)
  call say("intercept", weights(1))   ! Fortran arrays count from 1
  call say("weight_hours", weights(2))
  call say("weight_sleep", weights(3))
  call say("log_loss", log_loss)
  print "(a, 1x, i0)", "correct", correct
  call say("accuracy", real(correct, dp) / size(y_test))

contains

  ! An elemental function works on one number but also applies itself to
  ! every element of an array, so sigmoid(matmul(x, weights)) is a vector.
  elemental real(dp) function sigmoid(z)
    real(dp), intent(in) :: z
    sigmoid = 1 / (1 + exp(-z))
  end function sigmoid

  ! Read the CSV into training and test rows, sorted by the "split" column.
  subroutine read_rows(x, y, x_test, y_test)
    real(dp), allocatable, intent(out) :: x(:, :), y(:), x_test(:, :), y_test(:)
    character(len=256) :: path, header, line, text
    integer :: unit, status, c_hours, c_sleep, c_passed, c_split
    real(dp) :: row(3), label

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") header
    c_hours = field_index(header, "hours")
    c_sleep = field_index(header, "sleep")
    c_passed = field_index(header, "passed")
    c_split = field_index(header, "split")
    allocate(x(0, 3), y(0), x_test(0, 3), y_test(0))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      row(1) = 1
      text = field(line, c_hours)
      read(text, *) row(2)   ! an internal read parses the number
      text = field(line, c_sleep)
      read(text, *) row(3)
      text = field(line, c_passed)
      read(text, *) label
      if (field(line, c_split) == "train") then
        call append(x, y, row, label)
      else
        call append(x_test, y_test, row, label)
      end if
    end do
    close(unit)
  end subroutine read_rows

  ! Add one row to a matrix and its label to a vector. Fortran stores
  ! matrices column by column, so we rebuild the matrix one row longer.
  subroutine append(x, y, row, label)
    real(dp), allocatable, intent(inout) :: x(:, :), y(:)
    real(dp), intent(in) :: row(:), label
    real(dp), allocatable :: grown(:, :)

    allocate(grown(size(x, 1) + 1, size(x, 2)))
    grown(:size(x, 1), :) = x
    grown(size(x, 1) + 1, :) = row
    call move_alloc(grown, x)   ! x takes grown's storage
    y = [y, label]              ! grows the vector by one
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

end program logistic_regression
