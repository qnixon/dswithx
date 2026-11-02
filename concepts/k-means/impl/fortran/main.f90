! k-means clustering (Lloyd's algorithm), using only standard Fortran.
!
! Starts from the first K points as centroids, then alternates two steps until
! no point changes cluster: assign each point to its nearest centroid, and move
! each centroid to the mean of its points.

program k_means
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  integer, parameter :: k = 3, max_iterations = 100
  real(dp), allocatable :: points(:, :)
  real(dp) :: centroids(2, k), inertia
  integer, allocatable :: assignment(:), new_assignment(:)
  integer :: i, j, n, iterations, members
  character(len=20) :: name

  ! Fortran stores arrays column by column, so each point is a column:
  ! points(:, i) is the x and y of point i.
  points = read_points()
  n = size(points, 2)
  centroids = points(:, 1:k)   ! assignment copies; it is not a view
  allocate(assignment(n), new_assignment(n))
  assignment = 0   ! no cluster yet, so the first pass always differs

  iterations = 0
  do while (iterations < max_iterations)
    iterations = iterations + 1
    do i = 1, n
      new_assignment(i) = nearest_centroid(points(:, i))
    end do
    if (all(new_assignment == assignment)) exit
    assignment = new_assignment
    do j = 1, k
      members = count(assignment == j)
      if (members > 0) then   ! an empty cluster keeps its old centroid
        ! sum with a mask adds only the elements where the mask is true.
        centroids(1, j) = sum(points(1, :), mask=assignment == j) / members
        centroids(2, j) = sum(points(2, :), mask=assignment == j) / members
      end if
    end do
  end do

  inertia = 0
  do i = 1, n
    inertia = inertia + sum((points(:, i) - centroids(:, assignment(i)))**2)
  end do

  print "(a, 1x, i0)", "iterations", iterations
  do j = 1, k
    write(name, "(a, i0)") "centroid_", j   ! builds the name in a string
    call say(trim(name) // "_x", centroids(1, j))
    call say(trim(name) // "_y", centroids(2, j))
  end do
  do j = 1, k
    write(name, "(a, i0)") "size_", j
    print "(a, 1x, i0)", trim(name), count(assignment == j)
  end do
  call say("inertia", inertia)

contains

  ! The index of the centroid closest to a point. minloc returns the first
  ! of equal minimums, so a tie goes to the lower index.
  integer function nearest_centroid(point)
    real(dp), intent(in) :: point(2)
    real(dp) :: distance(k)
    integer :: j

    do j = 1, k
      distance(j) = norm2(point - centroids(:, j))   ! Euclidean distance
    end do
    nearest_centroid = minloc(distance, dim=1)
  end function nearest_centroid

  ! Every row of the file as a column of a 2-by-n array.
  function read_points() result(points)
    real(dp), allocatable :: points(:, :)
    real(dp), allocatable :: xs(:), ys(:)
    character(len=256) :: path, line, text
    integer :: unit, status, x_col, y_col
    real(dp) :: x, y

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") line
    x_col = field_index(line, "x")
    y_col = field_index(line, "y")
    allocate(xs(0), ys(0))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      text = field(line, x_col)
      read(text, *) x   ! an internal read parses the number
      text = field(line, y_col)
      read(text, *) y
      xs = [xs, x]   ! grows the array by one
      ys = [ys, y]
    end do
    close(unit)
    allocate(points(2, size(xs)))
    points(1, :) = xs   ! the first row holds every x
    points(2, :) = ys
  end function read_points

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

end program k_means
