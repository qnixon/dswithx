! Descriptive statistics on one CSV column, using only standard Fortran.
!
! Fortran has intrinsic sum, minval, and maxval for arrays, but no mean,
! median, variance, or sort, so those are written out.

program descriptive_statistics
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  character(len=*), parameter :: column = "minutes"
  real(dp), allocatable :: values(:)
  real(dp) :: total, mean, variance
  integer :: n

  values = read_column(column)
  call insertion_sort(values)

  n = size(values)
  total = sum(values)
  mean = total / n
  ! Sample variance divides by n - 1, not n (Bessel's correction).
  ! Whole-array arithmetic: values - mean subtracts from every element.
  variance = sum((values - mean)**2) / (n - 1)

  print "(a, 1x, i0)", "count", n
  call say("sum", total)
  call say("mean", mean)
  call say("median", median(values))
  call say("min", values(1))     ! Fortran arrays count from 1
  call say("max", values(n))
  call say("range", values(n) - values(1))
  call say("variance", variance)
  call say("std_dev", sqrt(variance))

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

  subroutine insertion_sort(a)
    real(dp), intent(inout) :: a(:)
    real(dp) :: key
    integer :: i, j

    do i = 2, size(a)
      key = a(i)
      j = i - 1
      do while (j >= 1)
        if (a(j) <= key) exit
        a(j + 1) = a(j)
        j = j - 1
      end do
      a(j + 1) = key
    end do
  end subroutine insertion_sort

  real(dp) function median(sorted)
    real(dp), intent(in) :: sorted(:)
    integer :: m

    m = size(sorted) / 2   ! integer division
    if (mod(size(sorted), 2) == 1) then
      median = sorted(m + 1)
    else
      median = (sorted(m) + sorted(m + 1)) / 2
    end if
  end function median

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

end program descriptive_statistics
