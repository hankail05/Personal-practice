#lang sicp
; Append this into analyze
((ramb? exp) (analyze-ramb exp))


(define (analyze-ramb exp)
  (let ((cproc (map analyze (ramb-list (ramb-contents exp) (length (ramb-contents exp))))))
    (lambda (env succeed fail)
      (define (try-next choices)
        (if (null? choices)
            (fail)
            ((car choices) env
                           succeed
                           (lambda () (try-next (cdr choices))))))
      (try-next cproc))))


(define (ramb? exp)
  (tagged-list? exp 'ramb))

(define (ramb-list exp n)
  (define (choose-iter exp n)
    (if (= n 1)
        (car exp)
        (choose-iter (cdr exp) (- n 1))))
  (define (exclude exp n)
    (if (= n 1)
        (cdr exp)
        (cons (car exp) (exclude (cdr exp) (- n 1)))))
  (if (= n 1)
      exp
      (let ((rand (+ (random (- n 1)) 1)))
        (cons (choose-iter exp rand)
              (ramb-list (exclude exp rand) (- n 1))))))

(define (ramb-contents exp) (cdr exp))