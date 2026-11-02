;;;; Principal component analysis by power iteration, using only standard
;;;; Common Lisp.
;;;;
;;;; Standardizes the four scores, builds their correlation matrix, and finds
;;;; the top two eigenvectors (the principal components): power iteration
;;;; finds the first, then deflation removes it from the matrix so the same
;;;; steps find the second. A vector is a list of numbers and a matrix is a
;;;; list of rows, so mapcar does most of the work. Common Lisp also has 2-D
;;;; arrays, read with (aref m i j), but lists need no index bookkeeping.

(defparameter *subjects* '("math" "physics" "reading" "writing"))
(defparameter *steps* 1000)

;; The scores are whole numbers, which parse-number turns into doubles. We
;; still read every decimal as a double, in the data and in this file, as
;; every program here does.
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

(defun read-rows (path names)
  "The columns called NAMES in the CSV file at PATH, as a list of rows of
numbers, in the order NAMES gives."
  (with-open-file (in path)
    (let* ((header (split-on-comma (read-line in)))
           (indexes (mapcar (lambda (name)
                              (or (position name header :test #'string=)
                                  (error "no column ~a" name)))
                            names)))
      (loop for line = (read-line in nil)
            while line
            unless (string= line "")
              collect (let ((fields (split-on-comma line)))
                        (mapcar (lambda (i) (parse-number (nth i fields))) indexes))))))

(defun transpose (rows)
  "The columns of ROWS. (mapcar #'list row1 row2 ...) collects the first
entry of every row, then the second, and so on; apply passes the rows as
those arguments."
  (apply #'mapcar #'list rows))

(defun dot (u v)
  "The sum of the products of U and V, entry by entry."
  (reduce #'+ (mapcar #'* u v)))

(defun mat-vec (m v)
  "A matrix times a vector: each row of M dotted with V."
  (mapcar (lambda (row) (dot row v)) m))

(defun normalize (v)
  (let ((length (sqrt (dot v v))))
    (mapcar (lambda (x) (/ x length)) v)))

(defun standardize (column)
  "COLUMN shifted to mean 0 and scaled to (sample) standard deviation 1."
  (let* ((n (length column))
         (mean (/ (reduce #'+ column) n))
         (sd (sqrt (/ (reduce #'+ (mapcar (lambda (x) (expt (- x mean) 2)) column))
                      (1- n)))))
    (mapcar (lambda (x) (/ (- x mean) sd)) column)))

(defun top-eigenvector (m)
  "Power iteration: multiply by M and rescale, *steps* times. Returns two
values, the eigenvalue and the eigenvector."
  (let ((v (cons 1.0 (make-list (1- (length m)) :initial-element 0.0))))
    (loop repeat *steps*
          do (setf v (normalize (mat-vec m v))))
    ;; An eigenvector can point either way; make its first entry positive.
    (when (minusp (first v))
      (setf v (mapcar #'- v)))
    (values (dot v (mat-vec m v)) v)))

(let* ((rows (read-rows (second sb-ext:*posix-argv*) *subjects*))
       (n (length rows))
       (k (length *subjects*))
       (columns (mapcar #'standardize (transpose rows)))
       (z (transpose columns))
       ;; The correlation matrix: the covariance of the standardized columns.
       (corr (mapcar (lambda (a)
                       (mapcar (lambda (b) (/ (dot a b) (1- n))) columns))
                     columns)))
  ;; multiple-value-bind catches both values top-eigenvector returns.
  (multiple-value-bind (value-1 pc-1) (top-eigenvector corr)
    ;; Deflation: subtract the first component's share, leaving the rest.
    (let ((deflated (mapcar (lambda (row a)
                              (mapcar (lambda (c b) (- c (* value-1 a b))) row pc-1))
                            corr pc-1)))
      (multiple-value-bind (value-2 pc-2) (top-eigenvector deflated)
        ;; ~d prints an integer, ~a a string, ~,6f a number with six
        ;; decimals, and ~% a newline.
        (format t "count ~d~%" n)
        (loop for c from 1
              for (value pc) in (list (list value-1 pc-1) (list value-2 pc-2))
              do (format t "eigenvalue_~d ~,6f~%" c value)
                 ;; Standardized columns each have variance 1, so the total is k.
                 (format t "explained_~d ~,6f~%" c (/ value k))
                 (loop for subject in *subjects*
                       for loading in pc
                       do (format t "pc~d_~a ~,6f~%" c subject loading)))
        (format t "student_1_pc1 ~,6f~%" (dot (first z) pc-1))
        (format t "student_1_pc2 ~,6f~%" (dot (first z) pc-2))))))
