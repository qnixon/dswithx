;;;; k-means clustering (Lloyd's algorithm), using only standard Common Lisp.
;;;;
;;;; Starts from the first k points as centroids, then alternates two steps
;;;; until no point changes cluster: assign each point to its nearest
;;;; centroid, and move each centroid to the mean of its points.

(defparameter *k* 3)
(defparameter *max-iterations* 100)

;; Read 1.25 as a double, not a single float with about 7 digits.
;; eval-when makes the setting apply while the compiler reads this file, too,
;; not only once the program runs.
(eval-when (:compile-toplevel :load-toplevel :execute)
  (setf *read-default-float-format* 'double-float))

;; defstruct defines a record type: make-point builds one, and point-x and
;; point-y read its fields.
(defstruct point x y)

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

(defun read-points (path)
  "The x and y columns of the CSV file at PATH, as a list of points."
  (with-open-file (in path)
    (let* ((header (split-on-comma (read-line in)))
           (xi (or (position "x" header :test #'string=) (error "no column x")))
           (yi (or (position "y" header :test #'string=) (error "no column y"))))
      (loop for line = (read-line in nil)
            while line
            unless (string= line "")
              collect (let ((fields (split-on-comma line)))
                        (make-point :x (parse-number (nth xi fields))
                                    :y (parse-number (nth yi fields))))))))

(defun squared-distance (p q)
  "Squared Euclidean distance. It ranks centroids in the same order as the
distance itself, so finding the nearest one needs no sqrt."
  (+ (expt (- (point-x p) (point-x q)) 2)
     (expt (- (point-y p) (point-y q)) 2)))

(defun nearest (point centroids)
  "The index of the centroid closest to POINT, counting from 0. Only a
strictly smaller distance replaces the best so far, so a tie goes to the
lower index."
  (loop with best = 0
        with best-distance = nil
        for centroid in centroids
        for j from 0
        for d = (squared-distance point centroid)
        when (or (null best-distance) (< d best-distance))
          do (setf best j best-distance d)
        finally (return best)))

(defun members (j points assignment)
  "The points assigned to cluster J."
  (loop for p in points
        for a in assignment
        when (= a j) collect p))

(defun mean (numbers)
  (/ (reduce #'+ numbers) (length numbers)))

(defun update (points assignment centroids)
  "Each centroid moved to the mean of its points. An empty cluster keeps its
old centroid."
  (loop for centroid in centroids
        for j from 0
        for group = (members j points assignment)
        collect (if (null group)
                    centroid
                    (make-point :x (mean (mapcar #'point-x group))
                                :y (mean (mapcar #'point-y group))))))

(let* ((points (read-points (second sb-ext:*posix-argv*)))
       ;; subseq copies the first k points into a new list.
       (centroids (subseq points 0 *k*))
       (assignment nil)
       (iterations 0))
  ;; Before the first pass the assignment is nil, the empty list, which no
  ;; real assignment equals. equal compares two lists element by element;
  ;; eq would only ask whether they are the same object in memory.
  (loop while (< iterations *max-iterations*)
        do (incf iterations)
           (let ((new (mapcar (lambda (p) (nearest p centroids)) points)))
             (when (equal new assignment)
               (return))
             (setf assignment new
                   centroids (update points assignment centroids))))
  (let ((inertia (loop for p in points
                       for a in assignment
                       sum (squared-distance p (nth a centroids)))))
    (format t "iterations ~d~%" iterations)
    ;; Clusters are numbered from 0 inside the program and from 1 in the output.
    (loop for c in centroids
          for j from 1
          do (format t "centroid_~d_x ~,6f~%" j (point-x c))
             (format t "centroid_~d_y ~,6f~%" j (point-y c)))
    (loop for j from 0 below *k*
          do (format t "size_~d ~d~%" (1+ j) (count j assignment)))
    (format t "inertia ~,6f~%" inertia)))
