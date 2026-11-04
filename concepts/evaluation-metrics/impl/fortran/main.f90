! Evaluation metrics for a binary classifier, using only standard Fortran.
!
! Reads each part's true label and the model's score, then reports the
! confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
! the accuracy of never flagging anything, and the area under the ROC curve.

program evaluation_metrics
  implicit none
  integer, parameter :: dp = kind(1.0d0)   ! double precision

  logical, allocatable :: defective(:)
  real(dp), allocatable :: score(:)
  integer :: n, positives

  call read_parts(defective, score)
  n = size(score)
  positives = count(defective)   ! count() counts the .true. elements

  print "(a, 1x, i0)", "parts", n
  print "(a, 1x, i0)", "defective", positives
  ! Never flagging anything is right about every good part.
  call say("baseline_accuracy", real(n - positives, dp) / n)
  call report("50", 0.5_dp)
  call report("30", 0.3_dp)
  call say("auc", auc())

contains

  ! The confusion matrix and the metrics built from it, at one threshold.
  subroutine report(suffix, threshold)
    character(len=*), intent(in) :: suffix
    real(dp), intent(in) :: threshold
    logical :: flagged(n)
    integer :: tp, fp, fn, tn
    real(dp) :: accuracy, precision, recall, f1

    ! A part is flagged when its score reaches the threshold. The comparison
    ! runs on the whole array at once, giving one .true. or .false. per part.
    flagged = score >= threshold
    tp = count(flagged .and. defective)
    fp = count(flagged .and. .not. defective)
    fn = count(.not. flagged .and. defective)
    tn = count(.not. flagged .and. .not. defective)

    accuracy = real(tp + tn, dp) / n
    precision = real(tp, dp) / (tp + fp)   ! of the flagged parts, how many are defective
    recall = real(tp, dp) / (tp + fn)      ! of the defective parts, how many are flagged
    f1 = 2 * precision * recall / (precision + recall)

    print "(a, 1x, i0)", "tp_at_" // suffix, tp
    print "(a, 1x, i0)", "fp_at_" // suffix, fp
    print "(a, 1x, i0)", "fn_at_" // suffix, fn
    print "(a, 1x, i0)", "tn_at_" // suffix, tn
    call say("accuracy_at_" // suffix, accuracy)
    call say("precision_at_" // suffix, precision)
    call say("recall_at_" // suffix, recall)
    call say("f1_at_" // suffix, f1)
  end subroutine report

  ! The chance that a random defective part outscores a random good one.
  ! Compare every pair, scoring 2 for a win and 1 for a tie, so the count
  ! stays a whole number until the final division.
  real(dp) function auc()
    real(dp), allocatable :: good(:)
    integer :: points, i

    good = pack(score, .not. defective)   ! pack keeps the elements where the mask is .true.
    points = 0
    do i = 1, n
      if (defective(i)) then
        ! One defective part against every good part at once.
        points = points + 2 * count(score(i) > good) + count(score(i) == good)
      end if
    end do
    auc = real(points, dp) / (2 * positives * size(good))
  end function auc

  subroutine read_parts(defective, score)
    logical, allocatable, intent(out) :: defective(:)
    real(dp), allocatable, intent(out) :: score(:)
    character(len=256) :: path, line, text
    integer :: unit, status, defective_col, score_col
    real(dp) :: x

    call get_command_argument(1, path)
    open(newunit=unit, file=path, status="old", action="read")
    read(unit, "(a)") line
    defective_col = field_index(line, "defective")
    score_col = field_index(line, "score")
    allocate(defective(0), score(0))
    do
      read(unit, "(a)", iostat=status) line
      if (status /= 0) exit
      if (len_trim(line) == 0) cycle
      ! An internal read parses a number. It must read from a variable,
      ! not straight from the result of field(), so we copy into text.
      text = field(line, score_col)
      read(text, *) x
      score = [score, x]   ! grows the array by one
      defective = [defective, field(line, defective_col) == "1"]
    end do
    close(unit)
  end subroutine read_parts

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

end program evaluation_metrics
