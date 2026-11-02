! Categorical naive Bayes with add-one (Laplace) smoothing, standard Fortran.
!
! Learns P(label) and P(feature value | label) by counting training rows, then
! labels each test row with the label that has the highest log-probability.

program naive_bayes
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision
  integer, parameter :: n_features = 3
  character(len=*), parameter :: features(n_features) = &
    [character(len=16) :: "has_link", "mentions_money", "known_sender"]

  ! One email: a value for each feature, and its label.
  type :: email
    character(len=16) :: values(n_features)
    character(len=16) :: label
  end type email

  type(email), allocatable :: train(:), test(:)
  character(len=16), allocatable :: labels(:)
  integer :: distinct_values(n_features), f, i, correct

  call read_emails(train, test)
  labels = sorted_labels()

  ! The number of distinct values of each feature: count each value the
  ! first time it appears. train%values(f) is that feature in every row.
  do f = 1, n_features
    distinct_values(f) = 0
    do i = 1, size(train)
      if (.not. any(train(:i - 1)%values(f) == train(i)%values(f))) &
        distinct_values(f) = distinct_values(f) + 1
    end do
  end do

  correct = 0
  do i = 1, size(test)
    if (classify(test(i)) == test(i)%label) correct = correct + 1
  end do

  print "(a, 1x, i0)", "train_count", size(train)
  print "(a, 1x, i0)", "test_count", size(test)
  print "(a, 1x, i0)", "correct", correct
  call say("accuracy", real(correct, dp) / size(test))

contains

  real(dp) function log_score(row, label)
    type(email), intent(in) :: row
    character(len=*), intent(in) :: label
    integer :: label_count, value_count, f

    ! Logs turn the product of probabilities into a sum, avoiding underflow.
    label_count = count(train%label == label)
    log_score = log(real(label_count, dp) / size(train))
    do f = 1, n_features
      ! Add-one smoothing: an unseen value never gets probability zero.
      value_count = count(train%label == label .and. &
                          train%values(f) == row%values(f)) + 1
      log_score = log_score + &
        log(real(value_count, dp) / (label_count + distinct_values(f)))
    end do
  end function log_score

  function classify(row) result(label)
    type(email), intent(in) :: row
    character(len=16) :: label
    real(dp) :: scores(size(labels))
    integer :: j

    do j = 1, size(labels)
      scores(j) = log_score(row, labels(j))
    end do
    ! maxloc returns the first of equal maximums, and the labels are sorted,
    ! so an exact tie goes to the alphabetically first label.
    label = labels(maxloc(scores, dim=1))
  end function classify

  ! The distinct training labels in alphabetical order (an insertion sort;
  ! < compares strings alphabetically).
  function sorted_labels() result(labels)
    character(len=16), allocatable :: labels(:)
    character(len=16) :: key
    integer :: i, j

    allocate(labels(0))
    do i = 1, size(train)
      if (.not. any(labels == train(i)%label)) labels = [labels, train(i)%label]
    end do
    do i = 2, size(labels)
      key = labels(i)
      j = i - 1
      do while (j >= 1)
        if (labels(j) <= key) exit
        labels(j + 1) = labels(j)
        j = j - 1
      end do
      labels(j + 1) = key
    end do
  end function sorted_labels

  subroutine read_emails(train, test)
    type(email), allocatable, intent(out) :: train(:), test(:)
    character(len=256) :: path, line
    integer :: unit, status, cols(n_features), label_col, split_col, f
    type(email) :: e

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") line
    do f = 1, n_features
      cols(f) = field_index(line, trim(features(f)))
    end do
    label_col = field_index(line, "label")
    split_col = field_index(line, "split")
    allocate(train(0), test(0))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      do f = 1, n_features
        e%values(f) = field(line, cols(f))
      end do
      e%label = field(line, label_col)
      if (field(line, split_col) == "train") then
        train = [train, e]   ! grows the array by one
      else
        test = [test, e]
      end if
    end do
    close(unit)
  end subroutine read_emails

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

end program naive_bayes
