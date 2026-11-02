;;;; A decision tree classifier (CART with Gini impurity), using only
;;;; standard Common Lisp.
;;;;
;;;; Grows a tree on the training days by always making the split that leaves
;;;; the two sides purest, then predicts rain for the test days. Prints the
;;;; tree in preorder: each node is either a split (feature and threshold) or
;;;; a leaf (its prediction).

;; Not *features*: that name belongs to Common Lisp, which keeps its list of
;; implementation features there.
(defparameter *feature-names* '("humidity" "pressure" "wind"))
(defparameter *max-depth* 3)
(defparameter *min-size* 5)

;; Read 1000.95 as a double, not a single float with about 7 digits.
;; eval-when makes the setting apply while the compiler reads this file, too,
;; not only once the program runs.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *read-default-float-format* 'double-float))

;;; The tree is a plain nested list, the same shape as Lisp code. A leaf is
;;; (:leaf rain), with rain t or nil, and a split is
;;; (:split feature threshold left right), where feature is a position in
;;; *feature-names* and left and right are smaller trees. Lists can hold
;;; lists, so a tree needs no type of its own, and you could print one with
;;; ~s and read it back. ecase picks the branch for a node's first item, the
;;; keyword, and destructuring-bind names the rest.

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

(defun read-days (path)
  "The training days and the test days, as two values. Each day is a cons:
the list of feature values, in the order of *feature-names*, and t if it
rained."
  (with-open-file (in path)
    (let ((header (split-on-comma (read-line in)))
          (train '())
          (test '()))
      (flet ((at (name)
               (or (position name header :test #'string=)
                   (error "no column ~a" name))))
        (loop for line = (read-line in nil)
              while line
              unless (string= line "")
                do (let* ((fields (split-on-comma line))
                          (day (cons (mapcar (lambda (name)
                                               (parse-number (nth (at name) fields)))
                                             *feature-names*)
                                     (string= (nth (at "rain") fields) "yes"))))
                     (if (string= (nth (at "split") fields) "train")
                         (push day train)
                         (push day test)))))
      ;; push adds to the front, so reverse restores the file's order.
      (values (reverse train) (reverse test)))))

(defun value (day f)
  "Feature F of DAY."
  (nth f (car day)))

(defun gini (days)
  "Chance that two days drawn at random (with replacement) disagree."
  (let ((p (/ (count-if #'cdr days) (length days))))
    (- 1 (* p p) (* (- 1 p) (- 1 p)))))

(defun majority (days)
  "T when strictly more than half the days rained, so an even split is nil."
  (> (* 2 (count-if #'cdr days)) (length days)))

(defun divide (days f threshold)
  "The days at or below THRESHOLD on feature F, then the rest, as two values."
  (values (remove-if-not (lambda (day) (<= (value day f) threshold)) days)
          (remove-if-not (lambda (day) (> (value day f) threshold)) days)))

(defun best-split (days)
  "The lowest weighted Gini impurity, with its feature and threshold, as
three values, or nil when every feature has a single value. Features go in
column order and thresholds from smallest to largest; only a strictly lower
score replaces the best so far, so the first split tried wins ties."
  (let ((best-score nil) best-f best-threshold)
    (dotimes (f (length *feature-names*))
      ;; remove-duplicates returns a fresh list, which sort may take apart.
      (let ((sorted (sort (remove-duplicates
                           (mapcar (lambda (day) (value day f)) days))
                          #'<)))
        ;; on walks the list's tails, so a and b are neighbors.
        (loop for (a b) on sorted
              while b
              do (let ((threshold (/ (+ a b) 2)))
                   (multiple-value-bind (left right) (divide days f threshold)
                     (let ((score (/ (+ (* (length left) (gini left))
                                        (* (length right) (gini right)))
                                     (length days))))
                       (when (or (null best-score) (< score best-score))
                         (setf best-score score
                               best-f f
                               best-threshold threshold))))))))
    (values best-score best-f best-threshold)))

(defun grow (days &optional (depth 0))
  "The tree for DAYS. A node becomes a leaf when it is pure, has fewer than
*min-size* days, reaches *max-depth*, or no split makes the sides purer."
  (let ((leaf (list :leaf (majority days)))
        (impurity (gini days)))
    (if (or (zerop impurity) (< (length days) *min-size*) (= depth *max-depth*))
        leaf
        (multiple-value-bind (score f threshold) (best-split days)
          (if (or (null score) (>= score impurity))
              leaf
              (multiple-value-bind (left right) (divide days f threshold)
                (list :split f threshold
                      (grow left (1+ depth))
                      (grow right (1+ depth)))))))))

(defun predict (tree x)
  "Follow the splits down to a leaf for the feature values X."
  (ecase (first tree)
    (:leaf (second tree))
    (:split (destructuring-bind (f threshold left right) (rest tree)
              (predict (if (<= (nth f x) threshold) left right) x)))))

(defun preorder (tree)
  "Every node in preorder: the node itself, then its left side, then its right."
  (ecase (first tree)
    (:leaf (list tree))
    (:split (destructuring-bind (f threshold left right) (rest tree)
              (declare (ignore f threshold))
              (cons tree (append (preorder left) (preorder right)))))))

(defun count-correct (tree days)
  "How many DAYS the tree labels correctly."
  (count-if (lambda (day) (eq (predict tree (car day)) (cdr day))) days))

;; With --script, the data path is the second item of *posix-argv*.
(multiple-value-bind (train test) (read-days (second sb-ext:*posix-argv*))
  (let* ((tree (grow train))
         (nodes (preorder tree))
         (correct (count-correct tree test)))
    ;; ~d prints an integer, ~a a string, ~,6f six decimals, ~% a newline.
    (format t "train_count ~d~%" (length train))
    (format t "test_count ~d~%" (length test))
    (loop for node in nodes
          for k from 1
          do (ecase (first node)
               (:leaf (format t "node_~d_predict ~a~%" k (if (second node) "yes" "no")))
               (:split (format t "node_~d_feature ~a~%"
                               k (nth (second node) *feature-names*))
                       (format t "node_~d_threshold ~,6f~%" k (third node)))))
    (format t "leaves ~d~%" (count :leaf nodes :key #'first))
    (format t "train_accuracy ~,6f~%" (/ (count-correct tree train) (length train)))
    (format t "correct ~d~%" correct)
    (format t "accuracy ~,6f~%" (/ correct (length test)))))
