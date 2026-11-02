;;;; Descriptive statistics on one CSV column, using only standard Common
;;;; Lisp.
;;;;
;;;; Every expression is a list with the operator first: (+ a b), (/ sum n).
;;;; Common Lisp has no mean, median, or variance, and no string split or
;;;; CSV reader, so we write those; sort, reduce, and sqrt are built in.

(defparameter *column* "minutes")

;; By default the reader turns 28.6 into a single float, which keeps only
;; about 7 digits; as a double that's 28.600000381469727. Read doubles.
;; eval-when makes the setting apply while the compiler reads this file, too,
;; not only once the program runs.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *read-default-float-format* 'double-float))

(defun split-on-comma (line)
  "The fields of LINE, split at every comma."
  (loop for start = 0 then (1+ end)
        for end = (position #\, line :start start)
        collect (subseq line start end)
        while end))

(defun parse-number (text)
  "The number written in TEXT, read by the Lisp reader. Binding *read-eval*
to nil stops the reader from running code written as #.(...)."
  (let ((*read-eval* nil))
    (coerce (read-from-string text) 'double-float)))

(defun read-column (path name)
  "The column called NAME in the CSV file at PATH, as a list of numbers."
  (with-open-file (in path)
    (let* ((header (split-on-comma (read-line in)))
           (index (or (position name header :test #'string=)
                      (error "no column ~a" name))))
      (loop for line = (read-line in nil)
            while line
            unless (string= line "")
              collect (parse-number (nth index (split-on-comma line)))))))

;; sort may take the list it's given apart, so we keep only what it returns.
;; With --script, the data path is the second item of *posix-argv*.
(let* ((minutes (sort (read-column (second sb-ext:*posix-argv*) *column*) #'<))
       (n (length minutes))
       (sum (reduce #'+ minutes))
       (mean (/ sum n))
       ;; Lists count from 0: for n = 120 the middle pair is at 59 and 60.
       ;; floor divides and rounds down, as integer division does elsewhere.
       (middle (floor n 2))
       (median (if (oddp n)
                   (nth middle minutes)
                   (/ (+ (nth (1- middle) minutes) (nth middle minutes)) 2)))
       ;; Sample variance divides by n - 1, not n (Bessel's correction).
       (variance (/ (reduce #'+ (mapcar (lambda (x) (expt (- x mean) 2)) minutes))
                    (1- n)))
       (low (first minutes))
       (high (car (last minutes))))
  ;; ~d prints an integer, ~,6f a number with six decimals, ~% a newline.
  (format t "count ~d~%" n)
  (format t "sum ~,6f~%" sum)
  (format t "mean ~,6f~%" mean)
  (format t "median ~,6f~%" median)
  (format t "min ~,6f~%" low)
  (format t "max ~,6f~%" high)
  (format t "range ~,6f~%" (- high low))
  (format t "variance ~,6f~%" variance)
  (format t "std_dev ~,6f~%" (sqrt variance)))
