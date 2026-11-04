;;;; Exact two-sided permutation test for a difference in means, using only
;;;; standard Common Lisp.
;;;;
;;;; If compost made no difference, the "compost" and "control" labels are
;;;; arbitrary, and any 8 of the 16 plants could have carried the compost
;;;; label. We try every one of those splits and count how many give a
;;;; difference at least as large as the one we observed. That fraction is
;;;; the p-value.

(defun split-on-comma (line)
  "The fields of LINE, split at every comma."
  (loop for start = 0 then (1+ end)
        for end = (position #\, line :start start)
        collect (subseq line start end)
        while end))

(defun read-plants (path)
  "The rows of the CSV file at PATH, as (group . grams) pairs in file order."
  (with-open-file (in path)
    (let* ((header (split-on-comma (read-line in)))
           (group-at (or (position "group" header :test #'string=)
                         (error "no column group")))
           (grams-at (or (position "grams" header :test #'string=)
                         (error "no column grams"))))
      (loop for line = (read-line in nil)
            while line
            unless (string= line "")
              collect (let ((fields (split-on-comma line)))
                        ;; parse-integer reads digits only; it never runs code.
                        (cons (nth group-at fields)
                              (parse-integer (nth grams-at fields))))))))

(defun grams-of (group rows)
  "The grams of every row in GROUP."
  (loop for (g . grams) in rows
        when (string= g group) collect grams))

(let* ((rows (read-plants (second sb-ext:*posix-argv*)))
       (control (grams-of "control" rows))
       (compost (grams-of "compost" rows))
       (n (length compost))
       (plants (coerce (append control compost) 'vector))
       (total (reduce #'+ plants))
       ;; Both groups have N plants, so comparing totals is the same as
       ;; comparing means, and integer totals stay whole numbers: no
       ;; floating-point near-ties.
       (observed (- (reduce #'+ compost) (reduce #'+ control)))
       (splits 0)
       (as-extreme 0))
  ;; Each whole number from 0 below 2^16 is a set of plants: bit I is on
  ;; when plant I is chosen. (ash 1 16) is 2^16. logcount counts the 1 bits,
  ;; so masks with exactly N of them are the splits, and logbitp tests one bit.
  (dotimes (mask (ash 1 (length plants)))
    (when (= (logcount mask) n)
      (let* ((chosen (loop for i below (length plants)
                           when (logbitp i mask) sum (aref plants i)))
             (difference (- chosen (- total chosen))))
        (incf splits)
        ;; Two-sided: a difference counts in either direction.
        (when (>= (abs difference) (abs observed))
          (incf as-extreme)))))
  ;; ~d prints an integer, ~,6f a number with six decimals, ~% a newline.
  ;; (/ 3231 8) would be the exact fraction 3231/8; dividing by a double
  ;; gives a double.
  (format t "control_count ~d~%" (length control))
  (format t "compost_count ~d~%" n)
  (format t "control_mean ~,6f~%" (/ (reduce #'+ control) (float (length control) 1d0)))
  (format t "compost_mean ~,6f~%" (/ (reduce #'+ compost) (float n 1d0)))
  (format t "observed_difference ~,6f~%" (/ observed (float n 1d0)))
  (format t "splits ~d~%" splits)
  (format t "as_extreme ~d~%" as-extreme)
  (format t "p_value ~,6f~%" (/ as-extreme (float splits 1d0))))
