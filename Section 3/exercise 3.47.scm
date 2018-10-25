#lang sicp
; a
(define (make-semaphore n)
  (let ((count 0)
        (mutex (make-mutex)))
    (define (semaphore m)
      (cond ((eq? m 'acquire) (set! count (+ count 1))
                              (if (= count 0)
                                  (mutex 'acquire))
                              (if (>= count n)
                                  (semaphore 'acquire)))
            ((eq? m 'acquire) (if (= count 0)
                                  (mutex 'release)
                                  (begin (set! count (- count 1))
                                         (mutex 'release))))))
    semaphore))
                                  


; b
(define (make-semaphore n)
  (let ((count 0)
        (cell (list false)))
    (define (semaphore m)
      (cond ((eq? m 'acquire) (if (test-and-set! cell)
                                  (semaphore m)
                                  (if (= count n)
                                      (clear! cell)
                                      (begin (set! count (+ count 1))
                                             (clear! cell)))))
            ((eq? m 'release) (if (= count 0)
                                  (clear! cell)
                                  (begin (set! count (- count 1))
                                         (clear! cell))))))))