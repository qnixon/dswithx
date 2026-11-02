;;;; Categorical naive Bayes with add-one (Laplace) smoothing, using only
;;;; standard Common Lisp.
;;;;
;;;; Learns P(label) and P(feature value | label) by counting training rows,
;;;; then labels each test row with the label that has the highest
;;;; log-probability. Counts live in hash tables.

;; Not *features*: Common Lisp already uses that name, and SBCL locks it.
(defparameter *feature-columns* '("has_link" "mentions_money" "known_sender"))

;; No numbers are read from this file, but every program here reads doubles.
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

(defun read-rows (path)
  "Every data row of the CSV file at PATH, as a hash table from column name
to value. Hash tables compare keys with eql by default, which treats two
equal strings as different keys; :test 'equal compares their characters."
  (with-open-file (in path)
    (let ((header (split-on-comma (read-line in))))
      (loop for line = (read-line in nil)
            while line
            unless (string= line "")
              collect (let ((row (make-hash-table :test 'equal)))
                        (loop for name in header
                              for value in (split-on-comma line)
                              do (setf (gethash name row) value))
                        row)))))

(defun column (name row)
  (or (gethash name row) (error "no column ~a" name)))

(defun divide (a b)
  "A divided by B as a double. (/ 55 150) is the exact fraction 11/30, and
the log of a fraction is a single float, accurate to about 7 digits."
  (/ (float a 1d0) b))

(defun rows-where (name value rows)
  (remove-if-not (lambda (row) (string= (column name row) value)) rows))

(let* ((rows (read-rows (second sb-ext:*posix-argv*)))
       (train (rows-where "split" "train" rows))
       (test (rows-where "split" "test" rows))
       (label-counts (make-hash-table :test 'equal))
       ;; Keyed by a list (feature value label), such as
       ;; ("has_link" "yes" "spam"); equal compares lists element by element.
       (value-counts (make-hash-table :test 'equal))
       (distinct-values (make-hash-table :test 'equal)))
  ;; gethash returns nil for a missing key; the 0 makes it start from zero.
  (dolist (row train)
    (let ((label (column "label" row)))
      (incf (gethash label label-counts 0))
      (dolist (f *feature-columns*)
        (incf (gethash (list f (column f row) label) value-counts 0)))))
  (dolist (f *feature-columns*)
    (setf (gethash f distinct-values)
          (length (remove-duplicates (mapcar (lambda (row) (column f row)) train)
                                     :test #'string=))))
  (labels ((log-score (row label)
             ;; Logs turn the product of probabilities into a sum, avoiding
             ;; underflow. Add-one smoothing means an unseen value never gets
             ;; probability zero.
             (let ((n-label (gethash label label-counts)))
               (+ (log (divide n-label (length train)))
                  (loop for f in *feature-columns*
                        for n-value = (gethash (list f (column f row) label) value-counts 0)
                        sum (log (divide (1+ n-value)
                                         (+ n-label (gethash f distinct-values))))))))
           (classify (row)
             ;; Labels are tried in alphabetical order, and only a strictly
             ;; higher score replaces the best, so a tie goes to the first.
             (let ((names (sort (loop for label being the hash-keys of label-counts
                                       collect label)
                                 #'string<)))
               (loop with best = (first names)
                     with best-score = (log-score row best)
                     for label in (rest names)
                     for score = (log-score row label)
                     when (> score best-score)
                       do (setf best label best-score score)
                     finally (return best)))))
    (let ((correct (count-if (lambda (row) (string= (classify row) (column "label" row)))
                             test)))
      (format t "train_count ~d~%" (length train))
      (format t "test_count ~d~%" (length test))
      (format t "correct ~d~%" correct)
      (format t "accuracy ~,6f~%" (divide correct (length test))))))
