;;;; Logistic regression by gradient descent, using only standard Common Lisp.
;;;;
;;;; Predicts whether a student passed from study hours and sleep. Each
;;;; feature is rescaled with the training rows' mean and standard deviation,
;;;; then the weights start at zero and take 1,000 steps of batch gradient
;;;; descent on the average log-loss. The students are a list of rows and the
;;;; weights are a list of three numbers: each step builds a new list.

(defparameter *feature-names* '("hours" "sleep"))
(defparameter *label* "passed")
(defparameter *learning-rate* 0.5)
(defparameter *steps* 1000)

;; By default the reader turns 7.8 into a single float, which keeps only
;; about 7 digits. Read doubles, both from the data and in this file.
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

(defun read-rows (path)
  "The CSV file at PATH as a list of rows. Each row is a function from a
column name to that row's field, as a string: (funcall row \"hours\")."
  (with-open-file (in path)
    (let ((header (split-on-comma (read-line in))))
      (flet ((row-lookup (fields)
               (lambda (name)
                 (nth (or (position name header :test #'string=)
                          (error "no column ~a" name))
                      fields))))
        (loop for line = (read-line in nil)
              while line
              unless (string= line "")
                collect (row-lookup (split-on-comma line)))))))

(defun features (row)
  "The feature values of ROW, as numbers."
  (mapcar (lambda (name) (parse-number (funcall row name))) *feature-names*))

(defun sigmoid (z)
  (/ 1 (+ 1 (exp (- z)))))

(defun dot (u v)
  "The sum of the products of U and V, entry by entry."
  (reduce #'+ (mapcar #'* u v)))

(defun mean (xs)
  (/ (reduce #'+ xs) (length xs)))

(defun sd (xs)
  "Sample standard deviation: divide by n - 1."
  (let ((m (mean xs)))
    (sqrt (/ (reduce #'+ (mapcar (lambda (x) (expt (- x m) 2)) xs))
             (1- (length xs))))))

(defun transpose (rows)
  "The columns of ROWS. (mapcar #'list row1 row2 ...) collects the first
entry of every row, then the second, and so on; apply passes the rows as
those arguments."
  (apply #'mapcar #'list rows))

(defun step-weights (xs ys weights)
  "One step of gradient descent. The gradient for weight j is the mean of
(p - y) times input j, summed over every student before any weight moves,
and the result is a new list of weights."
  (let* ((errors (mapcar (lambda (x y) (- (sigmoid (dot weights x)) y)) xs ys))
         (gradient (mapcar (lambda (column) (/ (dot errors column) (length xs)))
                           (transpose xs))))
    (mapcar (lambda (w g) (- w (* *learning-rate* g))) weights gradient)))

(let* ((rows (read-rows (second sb-ext:*posix-argv*)))
       (train (remove-if-not (lambda (r) (string= (funcall r "split") "train")) rows))
       (test (remove-if (lambda (r) (string= (funcall r "split") "train")) rows))
       ;; Scale with the training rows only.
       (columns (transpose (mapcar #'features train)))
       (means (mapcar #'mean columns))
       (sds (mapcar #'sd columns)))
  (flet ((scale (x)
           ;; The leading 1 multiplies the intercept.
           (cons 1.0 (mapcar (lambda (v m s) (/ (- v m) s)) x means sds)))
         (label (row)
           (parse-number (funcall row *label*))))
    (let* ((xs (mapcar (lambda (r) (scale (features r))) train))
           (ys (mapcar #'label train))
           (weights (list 0.0 0.0 0.0)))
      ;; Each pass replaces the whole list; no weight is changed in place.
      (loop repeat *steps*
            do (setf weights (step-weights xs ys weights)))
      (let ((log-loss (- (/ (reduce #'+ (mapcar (lambda (x y)
                                                  (let ((p (sigmoid (dot weights x))))
                                                    (+ (* y (log p))
                                                       (* (- 1 y) (log (- 1 p))))))
                                                xs ys))
                            (length xs))))
            (correct (count-if (lambda (r)
                                 (= (if (>= (sigmoid (dot weights (scale (features r)))) 0.5)
                                        1 0)
                                    (label r)))
                               test)))
        ;; ~d prints an integer, ~,6f a number with six decimals, ~% a newline.
        (format t "train_count ~d~%" (length train))
        (format t "test_count ~d~%" (length test))
        ;; destructuring-bind names the three weights in the list.
        (destructuring-bind (intercept hours sleep) weights
          (format t "intercept ~,6f~%" intercept)
          (format t "weight_hours ~,6f~%" hours)
          (format t "weight_sleep ~,6f~%" sleep))
        (format t "log_loss ~,6f~%" log-loss)
        (format t "correct ~d~%" correct)
        (format t "accuracy ~,6f~%" (/ correct (length test)))))))
