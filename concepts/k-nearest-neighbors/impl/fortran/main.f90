! k-nearest neighbors classification, using only standard Fortran.
!
! Each test seed is labelled with the majority variety among its K nearest
! training seeds, by Euclidean distance.

program k_nearest_neighbors
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  integer, parameter :: k = 5

  ! A derived type groups a seed's measurements with its variety.
  type :: seed
    real(dp) :: point(2)
    character(len=16) :: variety
  end type seed

  type(seed), allocatable :: train(:), test(:)
  integer :: i, correct

  call read_seeds(train, test)

  correct = 0
  do i = 1, size(test)
    if (classify(test(i)%point) == test(i)%variety) correct = correct + 1
  end do

  print "(a, 1x, i0)", "train_count", size(train)
  print "(a, 1x, i0)", "test_count", size(test)
  print "(a, 1x, i0)", "correct", correct
  call say("accuracy", real(correct, dp) / size(test))

contains

  function classify(point) result(variety)
    real(dp), intent(in) :: point(2)
    character(len=16) :: variety
    character(len=16) :: nearest(k)
    real(dp) :: distance(size(train))
    logical :: taken(size(train))
    integer :: votes(k), i, j

    ! norm2 is the Euclidean length of a vector, so this is the distance.
    do i = 1, size(train)
      distance(i) = norm2(point - train(i)%point)
    end do

    ! Take the closest untaken seed k times. minloc returns the first of
    ! equal minimums, so equal distances keep file order, like a stable sort.
    taken = .false.
    do i = 1, k
      j = minloc(distance, dim=1, mask=.not. taken)
      taken(j) = .true.
      nearest(i) = train(j)%variety
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

end program k_nearest_neighbors
