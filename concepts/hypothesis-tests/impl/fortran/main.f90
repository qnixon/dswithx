! Exact two-sided permutation test for a difference in means, using only
! standard Fortran.
!
! If compost made no difference, the "compost" and "control" labels are
! arbitrary, and any 8 of the 16 plants could have carried the compost label.
! We try every one of those splits and count how many give a difference at
! least as large as the one we observed. That fraction is the p-value.

program hypothesis_test
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision

  integer, allocatable :: control(:), compost(:), plants(:), chosen(:)
  integer :: n, m, total, observed, relabeled, difference, i, j
  integer :: splits, as_extreme

  call read_plants(control, compost)
  n = size(compost)
  plants = [control, compost]   ! the array constructor joins the two groups
  m = size(plants)
  total = sum(plants)

  ! Both groups have n plants, so comparing totals is the same as comparing
  ! means, and integer totals stay whole numbers: no floating-point near-ties.
  observed = sum(compost) - sum(control)

  ! chosen holds the positions of the n relabeled plants, in increasing
  ! order, starting from 1, 2, ..., n. Each pass moves to the next set in
  ! dictionary order, so every set comes up exactly once.
  chosen = [(i, i = 1, n)]   ! an implied-do loop builds [1, 2, ..., n]
  splits = 0
  as_extreme = 0
  do
    ! plants(chosen) is a vector subscript: the elements at those positions.
    relabeled = sum(plants(chosen))
    difference = relabeled - (total - relabeled)
    splits = splits + 1
    if (abs(difference) >= abs(observed)) as_extreme = as_extreme + 1   ! two-sided

    ! Find the rightmost position that can still move up. Position i can go
    ! no higher than m - n + i, or the positions after it would run out.
    i = n
    do while (i >= 1)
      if (chosen(i) < m - n + i) exit
      i = i - 1
    end do
    if (i == 0) exit   ! the last set, [m - n + 1, ..., m], is done
    ! Move it up by one, and set the positions after it to the next numbers
    ! in a row: if chosen(i) becomes 5, the ones after are 6, 7, and so on.
    chosen(i:) = chosen(i) + [(j, j = 1, n - i + 1)]
  end do

  print "(a, 1x, i0)", "control_count", size(control)
  print "(a, 1x, i0)", "compost_count", n
  call say("control_mean", real(sum(control), dp) / size(control))
  call say("compost_mean", real(sum(compost), dp) / n)
  call say("observed_difference", real(observed, dp) / n)
  print "(a, 1x, i0)", "splits", splits
  print "(a, 1x, i0)", "as_extreme", as_extreme
  call say("p_value", real(as_extreme, dp) / splits)

contains

  subroutine read_plants(control, compost)
    integer, allocatable, intent(out) :: control(:), compost(:)
    character(len=256) :: path, line, text
    integer :: unit, status, group_col, grams_col, grams

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") line
    group_col = field_index(line, "group")
    grams_col = field_index(line, "grams")
    allocate(control(0), compost(0))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      if (len_trim(line) == 0) cycle
      ! An internal read parses a number. It must read from a variable,
      ! not straight from the result of field(), so we copy into text.
      text = field(line, grams_col)
      read(text, *) grams
      if (field(line, group_col) == "control") then
        control = [control, grams]   ! grows the array by one
      else
        compost = [compost, grams]
      end if
    end do
    close(unit)
  end subroutine read_plants

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

end program hypothesis_test
