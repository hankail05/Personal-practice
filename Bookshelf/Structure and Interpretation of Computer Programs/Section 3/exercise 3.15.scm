#lang sicp
(define x (list 'a 'b))
(define z1 (cons x x))

; z1──> │
;      ├─┘
;      ∨
;  x──>a│──>b

(define z2 (cons (list 'a 'b) (list 'a 'b)))

; z2──> │──>a│──>b│/
;      │
;      │
;      └───>a│──>b│/

(define (set-to-wow! x)
  (set-car! (car x) 'wow)
  x)

(set-to-wow! z1)

; z1──> │
;      ├─┘
;      ∨
;  x──>wow│──>b

(set-to-wow! z2)

; z2──> │──>wow│──>b│/
;      │
;      │
;      └───>a│──>b│/