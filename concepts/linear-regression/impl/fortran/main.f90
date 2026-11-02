! Simple linear regression by least squares, using only standard Fortran.
!
! Fits score = intercept + slope * hours. Fortran has no regression or
! correlation intrinsic, so the sums are written out.

program linear_regression
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  real(dp), allocatable :: x(:), y(:)
  real(dp) :: mean_x, mean_y, sxx, syy, sxy, slope, intercept, r
  integer :: n

  x = read_column("hours")
  y = read_column("score")

  n = size(x)
  mean_x = sum(x) / n
  mean_y = sum(y) / n

  ! Sums of squared deviations and of cross-products. Whole-array
  ! arithmetic: x - mean_x is the array of every deviation.
  sxx = sum((x - mean_x)**2)
  syy = sum((y - mean_y)**2)
  sxy = dot_product(x - mean_x, y - mean_y)   ! sum of element-wise products

  slope = sxy / sxx
  intercept = mean_y - slope * mean_x
  r = sxy / sqrt(sxx * syy)

  print "(a, 1x, i0)", "count", n
  call say("slope", slope)
  call say("intercept", intercept)
  call say("r", r)
  call say("r_squared", r * r)

contains

  function read_column(name) result(column_values)
    character(len=*), intent(in) :: name
    real(dp), allocatable :: column_values(:)
    character(len=256) :: path, line, text
    integer :: unit, status, col
    real(dp) :: value

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") line
    col = field_index(line, name)
    allocate(column_values(0))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      text = field(line, col)
      read(text, *) value   ! an internal read parses the number
      column_values = [column_values, value]   ! grows the array by one
    end do
    close(unit)
  end function read_column

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

end program linear_regression
