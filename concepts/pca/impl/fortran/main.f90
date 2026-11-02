! Principal component analysis by power iteration, using only standard Fortran.
!
! Standardizes the four scores, builds their correlation matrix, and finds the
! top two eigenvectors (the principal components): power iteration finds the
! first, then deflation removes it from the matrix so the same steps find the
! second.

program pca
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  integer, parameter :: k = 4, steps = 1000
  character(len=*), parameter :: subjects(k) = &
    [character(len=7) :: "math", "physics", "reading", "writing"]
  real(dp), allocatable :: z(:, :)   ! one row per student, one column per subject
  real(dp) :: corr(k, k), deflated(k, k), pc_1(k), pc_2(k), value_1, value_2
  real(dp) :: mean, sd
  integer :: n, j

  z = read_scores()
  n = size(z, 1)

  ! Standardize each column to mean 0 and (sample) standard deviation 1.
  do j = 1, k
    mean = sum(z(:, j)) / n
    sd = sqrt(sum((z(:, j) - mean)**2) / (n - 1))
    z(:, j) = (z(:, j) - mean) / sd
  end do

  ! The correlation matrix: the covariance of the standardized columns.
  ! transpose(z) is k by n, so the product is k by k.
  corr = matmul(transpose(z), z) / (n - 1)

  call top_eigenvector(corr, value_1, pc_1)
  ! Deflation: subtract the first component's share, leaving the rest.
  ! spread copies pc_1 into k columns (or rows), so their product is the
  ! outer product pc_1(i) * pc_1(j).
  deflated = corr - value_1 * spread(pc_1, 2, k) * spread(pc_1, 1, k)
  call top_eigenvector(deflated, value_2, pc_2)

  print "(a, 1x, i0)", "count", n
  call report(1, value_1, pc_1)
  call report(2, value_2, pc_2)
  ! Fortran arrays count from 1, so the first student is row 1.
  call say("student_1_pc1", dot_product(z(1, :), pc_1))
  call say("student_1_pc2", dot_product(z(1, :), pc_2))

contains

  ! Power iteration: multiply by the matrix and rescale, steps times.
  subroutine top_eigenvector(m, value, v)
    real(dp), intent(in) :: m(k, k)
    real(dp), intent(out) :: value, v(k)
    integer :: step

    v = [1, 0, 0, 0]
    do step = 1, steps
      v = matmul(m, v)
      v = v / norm2(v)   ! norm2 is the vector's length
    end do
    ! An eigenvector can point either way; make its first entry positive.
    if (v(1) < 0) v = -v
    value = dot_product(v, matmul(m, v))   ! the Rayleigh quotient
  end subroutine top_eigenvector

  subroutine report(c, value, pc)
    integer, intent(in) :: c
    real(dp), intent(in) :: value, pc(k)
    character(len=20) :: name
    integer :: j

    write(name, "(a, i0)") "eigenvalue_", c
    call say(trim(name), value)
    ! Standardized columns each have variance 1, so the total is k.
    write(name, "(a, i0)") "explained_", c
    call say(trim(name), value / k)
    do j = 1, k
      write(name, "(a, i0, a, a)") "pc", c, "_", trim(subjects(j))
      call say(trim(name), pc(j))
    end do
  end subroutine report

  ! Read the four subject columns into an n by k matrix.
  function read_scores() result(scores)
    real(dp), allocatable :: scores(:, :), grown(:, :)
    character(len=256) :: path, header, line, text
    integer :: unit, status, cols(k), j

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") header
    do j = 1, k
      cols(j) = field_index(header, trim(subjects(j)))
    end do
    allocate(scores(0, k))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      ! Fortran stores matrices column by column, so we rebuild the matrix
      ! one row longer; move_alloc hands grown's storage to scores.
      allocate(grown(size(scores, 1) + 1, k))
      grown(:size(scores, 1), :) = scores
      do j = 1, k
        text = field(line, cols(j))
        read(text, *) grown(size(grown, 1), j)   ! an internal read parses it
      end do
      call move_alloc(grown, scores)
    end do
    close(unit)
  end function read_scores

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

end program pca
