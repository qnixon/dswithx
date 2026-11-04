;;;; Evaluation metrics for a binary classifier, using only standard
;;;; Common Lisp.
;;;;
;;;; Reads each part's true label and the model's score, then reports the
;;;; confusion matrix, accuracy, precision, recall, and F1 at two thresholds,
;;;; the accuracy of never flagging anything, and the area under the ROC
;;;; curve.

(defun split-on-comma (line)
  "The fields of LINE, split at every comma."
  (loop for start = 0 then (1+ end)
        for end = (position #\, line :start start)
        collect (subseq line start end)
        while end))

(defun thousandths (text)
  "A score such as \"0.174\" as the whole number of thousandths, 174.
parse-integer reads digits only; it never runs code, as READ could."
  (parse-integer (remove #\. text)))

(defun read-parts (path)
  "The rows of the CSV file at PATH, as (defective . score) pairs in file
order. Scores are whole thousandths, so equal scores stay exactly equal."
  (with-open-file (in path)
    (let* ((header (split-on-comma (read-line in)))
           (defective-at (or (position "defective" header :test #'string=)
                             (error "no column defective")))
           (score-at (or (position "score" header :test #'string=)
                         (error "no column score"))))
      (loop for line = (read-line in nil)
            while line
            unless (string= line "")
              collect (let ((fields (split-on-comma line)))
                        (cons (string= (nth defective-at fields) "1")
                              (thousandths (nth score-at fields))))))))

;;; ~d prints an integer, ~,6f a number with six decimals, ~a a string, and
;;; ~% a newline. Dividing two integers gives an exact fraction, like 5/7,
;;; so every ratio stays exact until (float x 1d0) makes it a double.

(defun print-metrics (parts suffix threshold)
  "Print the confusion matrix and its metrics when parts scoring THRESHOLD
thousandths or more are flagged."
  (let ((tp 0) (fp 0) (fn 0) (tn 0))
    (loop for (defective . score) in parts
          for flagged = (>= score threshold)
          do (cond ((and flagged defective) (incf tp))
                   (flagged (incf fp))
                   (defective (incf fn))
                   (t (incf tn))))
    (let* ((accuracy (/ (+ tp tn) (length parts)))
           (precision (/ tp (+ tp fp)))  ; of the flagged parts, how many are defective
           (recall (/ tp (+ tp fn)))     ; of the defective parts, how many are flagged
           (f1 (/ (* 2 precision recall) (+ precision recall))))
      (format t "tp_at_~a ~d~%" suffix tp)
      (format t "fp_at_~a ~d~%" suffix fp)
      (format t "fn_at_~a ~d~%" suffix fn)
      (format t "tn_at_~a ~d~%" suffix tn)
      (format t "accuracy_at_~a ~,6f~%" suffix (float accuracy 1d0))
      (format t "precision_at_~a ~,6f~%" suffix (float precision 1d0))
      (format t "recall_at_~a ~,6f~%" suffix (float recall 1d0))
      (format t "f1_at_~a ~,6f~%" suffix (float f1 1d0)))))

(defun auc (parts)
  "The chance that a random defective part outscores a random good one.
Every pair scores 2 for a win and 1 for a tie, so the count stays a whole
number until the final division."
  (let ((defective (loop for (d . s) in parts when d collect s))
        (good (loop for (d . s) in parts unless d collect s)))
    (/ (loop for d in defective
             sum (loop for g in good
                       sum (cond ((> d g) 2) ((= d g) 1) (t 0))))
       (* 2 (length defective) (length good)))))

(let* ((parts (read-parts (second sb-ext:*posix-argv*)))
       (n (length parts))
       (defective (count-if #'car parts)))
  (format t "parts ~d~%" n)
  (format t "defective ~d~%" defective)
  ;; Never flagging anything is right about every good part.
  (format t "baseline_accuracy ~,6f~%" (float (/ (- n defective) n) 1d0))
  ;; The thresholds 0.5 and 0.3, in thousandths.
  (print-metrics parts "50" 500)
  (print-metrics parts "30" 300)
  (format t "auc ~,6f~%" (float (auc parts) 1d0)))
