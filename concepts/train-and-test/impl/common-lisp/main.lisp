;;;; Train and test error for polynomials of degree 1 to 8, using only
;;;; standard Common Lisp.
;;;;
;;;; Each polynomial is fitted by least squares to the training drives only:
;;;; we build the normal equations and solve them by Gaussian elimination.
;;;; Then we measure its root-mean-square error on the training drives and
;;;; on the test drives it never saw. The equations sit in a 2-D array, read
;;;; and written with (aref m i j).

(defparameter *max-degree* 8)

;; Read every decimal as a double, in the data and in this file.
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

(defun read-drives (path)
  "The rows of the CSV file at PATH as two lists of (speed . litres) pairs,
the training drives and the test drives, each in file order."
  (with-open-file (in path)
    (let* ((header (split-on-comma (read-line in)))
           (column (lambda (name)
                     (or (position name header :test #'string=)
                         (error "no column ~a" name))))
           (speed-at (funcall column "speed"))
           (litres-at (funcall column "litres"))
           (split-at (funcall column "split"))
           (train '())
           (test '()))
      (loop for line = (read-line in nil)
            while line
            unless (string= line "")
              do (let* ((fields (split-on-comma line))
                        (point (cons (parse-number (nth speed-at fields))
                                     (parse-number (nth litres-at fields)))))
                   (if (string= (nth split-at fields) "train")
                       (push point train)
                       (push point test))))
      ;; push adds to the front, so reverse restores the file order.
      (values (reverse train) (reverse test)))))

(defun solve (a b n)
  "Solve A x = B, N equations in N unknowns, by Gaussian elimination with
partial pivoting. A is an N by N array and B a vector; x comes back as a
vector."
  ;; The augmented matrix: A with B as an extra last column.
  (let ((m (make-array (list n (1+ n)))))
    (dotimes (i n)
      (dotimes (j n)
        (setf (aref m i j) (aref a i j)))
      (setf (aref m i n) (aref b i)))
    (dotimes (col n)
      ;; Swap up the row with the largest entry in this column, which keeps
      ;; the rounding error small. A 2-D array has no row objects to swap,
      ;; so rotatef swaps the two rows one entry at a time.
      (let ((pivot col))
        (loop for r from (1+ col) below n
              when (> (abs (aref m r col)) (abs (aref m pivot col)))
                do (setf pivot r))
        (dotimes (c (1+ n))
          (rotatef (aref m col c) (aref m pivot c))))
      (loop for r from (1+ col) below n
            do (let ((factor (/ (aref m r col) (aref m col col))))
                 (loop for c from col to n
                       do (decf (aref m r c) (* factor (aref m col c)))))))
    ;; Back substitution, from the last unknown up.
    (let ((x (make-array n :initial-element 0d0)))
      (loop for r from (1- n) downto 0
            do (setf (aref x r)
                     (/ (- (aref m r n)
                           (loop for c from (1+ r) below n
                                 sum (* (aref m r c) (aref x c))))
                        (aref m r r))))
      x)))

(defun fit (points degree)
  "Least squares: the coefficients c solve (Z^T Z) c = Z^T y, where row i of
Z is 1, z_i, z_i^2, ..., z_i^degree. POINTS holds (z . y) pairs."
  (let* ((size (1+ degree))
         (a (make-array (list size size) :initial-element 0d0))
         (b (make-array size :initial-element 0d0)))
    (loop for (z . y) in points
          do (dotimes (i size)
               (incf (aref b i) (* y (expt z i)))
               (dotimes (j size)
                 (incf (aref a i j) (expt z (+ i j))))))
    (solve a b size)))

(defun rmse (coefs points)
  (let ((total (loop for (z . y) in points
                     sum (let ((predicted (loop for c across coefs
                                                for i from 0
                                                sum (* c (expt z i)))))
                           (expt (- predicted y) 2)))))
    (sqrt (/ total (length points)))))

(multiple-value-bind (train test) (read-drives (second sb-ext:*posix-argv*))
  ;; Map the training speeds onto -1 to 1. Raw speeds to the 16th power (the
  ;; largest entry at degree 8) would swamp the small ones and make the
  ;; equations hard to solve accurately.
  (let* ((low (reduce #'min (mapcar #'car train)))
         (high (reduce #'max (mapcar #'car train)))
         (mid (/ (+ low high) 2))
         (half (/ (- high low) 2))
         (scale (lambda (points)
                  (mapcar (lambda (p) (cons (/ (- (car p) mid) half) (cdr p)))
                          points)))
         (train-z (funcall scale train))
         (test-z (funcall scale test))
         (fits (loop for degree from 1 to *max-degree*
                     collect (fit train-z degree))))
    ;; ~d prints an integer and ~,6f a number with six decimals.
    (format t "train_count ~d~%" (length train))
    (format t "test_count ~d~%" (length test))
    (loop for coefs in fits
          for degree from 1
          do (format t "train_rmse_d~d ~,6f~%" degree (rmse coefs train-z)))
    (loop for coefs in fits
          for degree from 1
          do (format t "test_rmse_d~d ~,6f~%" degree (rmse coefs test-z)))))
