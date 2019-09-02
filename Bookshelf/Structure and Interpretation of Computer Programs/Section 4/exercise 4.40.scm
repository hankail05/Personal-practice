#lang sicp
(define (multiple-dwelling)
  (let ((cooper (amb 1 2 3 4 5)))
    (require (not (= cooper 1)))
    (let ((miller (amb 1 2 3 4 5)))
      (require (> miller cooper))
      (let ((fletcher (amb 1 2 3 4 5)))
        (require (not (= fletcher 1)))
        (require (not (= fletcher 5)))
        (let ((smith (amb 1 2 3 4 5)))
          (require (not (= (abs (- smith fletcher)) 1)))
          (require (not (= (abs (- cooper fletcher)) 1)))
          (let ((baker (amb 1 2 3 4 5)))
            (require (not (= baker 5)))
            (require (distinct? (list baker cooper fletcher miller smith)))
            (list (list 'baker baker)
                  (list 'cooper cooper)
                  (list 'fletcher fletcher)
                  (list 'miller miller)
                  (list 'smith smith))))))))