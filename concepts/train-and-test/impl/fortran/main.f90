! Train and test error for polynomials of degree 1 to 8, using only standard
! Fortran.
!
! Each polynomial is fitted by least squares to the training drives only: we
! build the normal equations and solve them by Gaussian elimination. Then we
! measure its root-mean-square error on the training drives and on the test
! drives it never saw.

program train_and_test
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  integer, parameter :: max_degree = 8

  real(dp), allocatable :: speed(:), litres(:), train_z(:), train_y(:), test_z(:), test_y(:)
  logical, allocatable :: is_train(:)
  real(dp) :: mid, half, coefs(0:max_degree), train_rmse(max_degree), test_rmse(max_degree)
  character(len=20) :: name
  integer :: d

  call read_drives(speed, litres, is_train)

  ! Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
  ! largest entry at degree 8) would swamp the small ones and make the
  ! equations hard to solve accurately. pack keeps the elements where the
  ! mask is .true.
  train_y = pack(litres, is_train)
  test_y = pack(litres, .not. is_train)
  train_z = pack(speed, is_train)
  mid = (minval(train_z) + maxval(train_z)) / 2
  half = (maxval(train_z) - minval(train_z)) / 2
  train_z = (train_z - mid) / half
  test_z = (pack(speed, .not. is_train) - mid) / half

  do d = 1, max_degree
    coefs(:d) = fit(train_z, train_y, d)
    train_rmse(d) = rmse(coefs(:d), train_z, train_y)
    test_rmse(d) = rmse(coefs(:d), test_z, test_y)
  end do

  print "(a, 1x, i0)", "train_count", size(train_y)
  print "(a, 1x, i0)", "test_count", size(test_y)
  do d = 1, max_degree
    write(name, "(a, i0)") "train_rmse_d", d
    call say(trim(name), train_rmse(d))
  end do
  do d = 1, max_degree
    write(name, "(a, i0)") "test_rmse_d", d
    call say(trim(name), test_rmse(d))
  end do

contains

  ! The design matrix: row i is 1, z_i, z_i^2, ..., z_i^degree. Its columns
  ! count from 0, so column j holds z to the power j.
  function powers(z, degree) result(m)
    real(dp), intent(in) :: z(:)
    integer, intent(in) :: degree
    real(dp) :: m(size(z), 0:degree)
    integer :: j

    do j = 0, degree
      m(:, j) = z**j
    end do
  end function powers

  ! Least squares: the coefficients c solve (Z^T Z) c = Z^T y.
  function fit(z, y, degree) result(c)
    real(dp), intent(in) :: z(:), y(:)
    integer, intent(in) :: degree
    real(dp) :: c(0:degree), zm(size(z), 0:degree)

    zm = powers(z, degree)
    c = solve(matmul(transpose(zm), zm), matmul(transpose(zm), y))
  end function fit

  real(dp) function rmse(c, z, y)
    real(dp), intent(in) :: c(0:), z(:), y(:)

    rmse = sqrt(sum((matmul(powers(z, size(c) - 1), c) - y)**2) / size(y))
  end function rmse

  ! Solve a x = b by Gaussian elimination with partial pivoting.
  function solve(a, b) result(x)
    real(dp), intent(in) :: a(:, :), b(:)
    real(dp) :: x(size(b)), m(size(b), size(b) + 1), row(size(b) + 1), factor
    integer :: n, col, pivot, r

    n = size(b)
    ! The augmented matrix: a with b as an extra last column.
    m(:, :n) = a
    m(:, n + 1) = b
    do col = 1, n
      ! Swap up the row with the largest entry in this column, which keeps
      ! the rounding error small. maxloc gives the position within the
      ! section col:n, so we shift it back to a row number.
      pivot = maxloc(abs(m(col:, col)), 1) + col - 1
      row = m(col, :)
      m(col, :) = m(pivot, :)
      m(pivot, :) = row
      do r = col + 1, n
        factor = m(r, col) / m(col, col)
        ! One statement updates the whole rest of the row.
        m(r, col:) = m(r, col:) - factor * m(col, col:)
      end do
    end do
    ! Back substitution, from the last unknown up.
    do r = n, 1, -1
      x(r) = (m(r, n + 1) - dot_product(m(r, r + 1:n), x(r + 1:n))) / m(r, r)
    end do
  end function solve

  subroutine read_drives(speed, litres, is_train)
    real(dp), allocatable, intent(out) :: speed(:), litres(:)
    logical, allocatable, intent(out) :: is_train(:)
    character(len=256) :: path, line, text
    integer :: unit, status, speed_col, litres_col, split_col
    real(dp) :: x, y

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") line
    speed_col = field_index(line, "speed")
    litres_col = field_index(line, "litres")
    split_col = field_index(line, "split")
    allocate(speed(0), litres(0), is_train(0))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      if (len_trim(line) == 0) cycle
      ! An internal read parses a number. It must read from a variable,
      ! not straight from the result of field(), so we copy into text.
      text = field(line, speed_col)
      read(text, *) x
      text = field(line, litres_col)
      read(text, *) y
      speed = [speed, x]   ! grows the array by one
      litres = [litres, y]
      is_train = [is_train, field(line, split_col) == "train"]
    end do
    close(unit)
  end subroutine read_drives

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

end program train_and_test
