;;;; k-nearest neighbors classification, using only standard Common Lisp.
;;;;
;;;; Each test seed is labelled with the majority variety among its K
;;;; nearest training seeds, by Euclidean distance. Common Lisp has no kNN,
;;;; no distance function, and no CSV reader, so we write those; sqrt,
;;;; stable-sort, and count are built in.

(defparameter *k* 5)

;; By default the reader turns 5.50 into a single float, which keeps only
;; about 7 digits. Read doubles.
;; eval-when makes the setting apply while the compiler reads this file, too,
;; not only once the program runs.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *read-default-float-format* 'double-float))

;; defstruct defines a record type with a constructor, make-seed, and one
;; reader per slot: seed-length, seed-width, seed-variety, seed-split.
(defstruct seed length width variety split)

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

(defun read-seeds (path)
  "The rows of the CSV file at PATH, as a list of seeds in file order."
  (with-open-file (in path)
    (let ((header (split-on-comma (read-line in))))
      ;; Each field's position in the header, looked up by name.
      (flet ((column (name)
               (or (position name header :test #'string=)
                   (error "no column ~a" name))))
        (let ((length-at (column "length_mm"))
              (width-at (column "width_mm"))
              (variety-at (column "variety"))
              (split-at (column "split")))
          (loop for line = (read-line in nil)
                while line
                unless (string= line "")
                  collect (let ((fields (split-on-comma line)))
                            (make-seed
                             :length (parse-number (nth length-at fields))
                             :width (parse-number (nth width-at fields))
                             :variety (nth variety-at fields)
                             :split (nth split-at fields)))))))))

(defun distance (a b)
  "The Euclidean distance between seeds A and B."
  (sqrt (+ (expt (- (seed-length a) (seed-length b)) 2)
           (expt (- (seed-width a) (seed-width b)) 2))))

(defun classify (point train)
  "The majority variety among the K training seeds nearest POINT."
  ;; stable-sort keeps equal distances in file order; plain sort may not.
  ;; It may take its argument apart, so we sort a fresh copy of TRAIN.
  (let* ((nearest (subseq (stable-sort (copy-list train) #'<
                                       :key (lambda (s) (distance point s)))
                          0 *k*))
         (votes (mapcar #'seed-variety nearest))
         (best nil)
         (best-count 0))
    ;; Count each variety's votes, in the order the neighbors came. Only a
    ;; strictly larger count replaces the leader, so the first wins a tie.
    (dolist (variety (remove-duplicates votes :test #'string= :from-end t)
                     best)
      (let ((n (count variety votes :test #'string=)))
        (when (> n best-count)
          (setf best variety
                best-count n))))))

;; With --script, the data path is the second item of *posix-argv*.
(let* ((seeds (read-seeds (second sb-ext:*posix-argv*)))
       (train (remove-if-not (lambda (s) (string= (seed-split s) "train")) seeds))
       (test (remove-if-not (lambda (s) (string= (seed-split s) "test")) seeds))
       (correct (count-if (lambda (s)
                            (string= (classify s train) (seed-variety s)))
                          test)))
  ;; ~d prints an integer, ~,6f a number with six decimals, ~% a newline.
  (format t "train_count ~d~%" (length train))
  (format t "test_count ~d~%" (length test))
  (format t "correct ~d~%" correct)
  ;; (/ 47 50) would be the exact fraction 47/50; dividing by a double
  ;; gives a double.
  (format t "accuracy ~,6f~%" (/ correct (float (length test) 1d0))))
