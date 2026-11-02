;;;; Simple linear regression by least squares, using only standard Common
;;;; Lisp.
;;;;
;;;; Fits score = intercept + slope * hours. Common Lisp has no regression,
;;;; correlation, or mean function, and no CSV reader, so we write the sums
;;;; out; reduce, mapcar, and sqrt are built in.

(defparameter *x-column* "hours")
(defparameter *y-column* "score")

;; By default the reader turns 5.7 into a single float, which keeps only
;; about 7 digits. Read doubles.
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

(defun mean (numbers)
  "The arithmetic mean of NUMBERS."
  (/ (reduce #'+ numbers) (length numbers)))

;; With --script, the data path is the second item of *posix-argv*.
(let* ((path (second sb-ext:*posix-argv*))
       (xs (read-column path *x-column*))
       (ys (read-column path *y-column*))
       (n (length xs))
       ;; First pass: the means. Second pass: deviations from them.
       (mean-x (mean xs))
       (mean-y (mean ys))
       (dxs (mapcar (lambda (x) (- x mean-x)) xs))
       (dys (mapcar (lambda (y) (- y mean-y)) ys))
       ;; Given two lists, mapcar walks them side by side, so #'* multiplies
       ;; each hours deviation by the score deviation from the same row.
       (sxx (reduce #'+ (mapcar #'* dxs dxs)))
       (syy (reduce #'+ (mapcar #'* dys dys)))
       (sxy (reduce #'+ (mapcar #'* dxs dys)))
       (slope (/ sxy sxx))
       (intercept (- mean-y (* slope mean-x)))
       (r (/ sxy (sqrt (* sxx syy)))))
  ;; ~d prints an integer, ~,6f a number with six decimals, ~% a newline.
  (format t "count ~d~%" n)
  (format t "slope ~,6f~%" slope)
  (format t "intercept ~,6f~%" intercept)
  (format t "r ~,6f~%" r)
  (format t "r_squared ~,6f~%" (* r r)))
