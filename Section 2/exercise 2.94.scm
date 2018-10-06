#lang sicp
(define global-array '())
(define (make-entry k v) (list k v))
(define (key entry) (car entry))
(define (value entry) (cadr entry))
(define (put op type item)
  (define (put-helper k array)
    (cond ((null? array) (list (make-entry k item)))
          ((equal? (key (car array)) k) array)
          (else (cons (car array) (put-helper k (cdr array))))))
  (set! global-array (put-helper (list op type) global-array)))
(define (get op type)
  (define (get-helper k array)
    (cond ((null? array) #f)
          ((equal? (key (car array)) k) (value (car array)))
          (else (get-helper k (cdr array)))))
  (get-helper (list op type) global-array))
; get/put


(define (attach-tag type-tag contents)
  (if (number? contents) contents (cons type-tag contents)))
(define (type-tag datum)
  (cond ((number? datum) 'integer)
        ((pair? datum) (car datum))
        (else (error "Bad tagged datum -- TYPE-TAG" datum))))
(define (contents datum)
  (cond ((number? datum) datum)
        ((pair? datum) (cdr datum))
        (else (error "Bad tagged datum -- CONTENTS" datum))))

(define (apply-generic op . args)
  (define type-tower (list (list 'integer 1) (list 'rational 2) (list 'real 3) (list 'complex 4)))
  (define (type-rank type tower) (cond ((null? tower) (error "Undefined type"))
                                       ((eq? type (type-tag (car tower))) (car (contents (car tower))))
                                       (else (type-rank type (cdr tower)))))
  (let ((type-tags (map type-tag args)))
    (let ((proc (get op type-tags)))
      (cond (proc (if (or (eq? op 'add) (eq? op 'sub) (eq? op 'mul) (eq? op 'div))
                      (drop (apply proc (map contents args)))
                      (apply proc (map contents args))))
            ((= (length args) 2) (let ((type-rank1 (type-rank (car type-tags) type-tower))
                                       (type-rank2 (type-rank (cadr type-tags) type-tower))
                                       (a1 (car args)) (a2 (cadr args)))
                                   (define (tower-coercion type-rank1 type-rank2 a1 a2)
                                     (cond ((< type-rank1 type-rank2) (tower-coercion (+ type-rank1 1) type-rank2 (raise a1) a2))
                                           ((> type-rank1 type-rank2) (tower-coercion type-rank1 (+ type-rank2 1) a1 (raise a2)))
                                           ((= type-rank1 type-rank2) (apply-generic op a1 a2))
                                           (else (error "No method for these types" (list op type-tags)))))
                                   (tower-coercion type-rank1 type-rank2 a1 a2)))
            (else
             (error "No method for these types" (list op type-tags)))))))


(define (install-integer-package)
  (define (tag x) (attach-tag 'integer x))
  (put 'add '(integer integer) (lambda (x y) (tag (+ x y))))
  (put 'sub '(integer integer) (lambda (x y) (tag (- x y))))
  (put 'mul '(integer integer) (lambda (x y) (tag (* x y))))
  (put 'div '(integer integer) (lambda (x y) (tag (/ x y))))
  (put 'equ '(integer integer) (lambda (x y) (= x y)))
  (put 'zero '(integer) (lambda (x) (= x 0)))
  (put 'neg '(integer) (lambda (x) (make-integer (- x))))
  (put 'gcd '(integer integer) gcd)
  (put 'make 'integer (lambda (x) (tag x)))
  'done)

(define (make-integer n) ((get 'make 'integer) n))


(define (install-rational-package)
  (define (numer x) (car x))
  (define (denom x) (cdr x))
  (define (make-rat n d) (cons n d))
  (define (add-rat x y)
    (make-rat (add (mul (numer x) (denom y)) (mul (numer y) (denom x))) (mul (denom x) (denom y))))
  (define (sub-rat x y)
    (make-rat (sub (mul (numer x) (denom y)) (mul (numer y) (denom x))) (mul (denom x) (denom y))))
  (define (mul-rat x y)
    (make-rat (mul (numer x) (numer y)) (mul (denom x) (denom y))))
  (define (div-rat x y)
    (make-rat (mul (numer x) (denom y)) (mul (denom x) (numer y))))
  (define (equ-rat x y)
    (equ? (mul (numer x) (denom y)) (mul (denom x) (numer y))))

  (define (tag x) (attach-tag 'rational x))
  (put 'add '(rational rational) (lambda (x y) (tag (add-rat x y))))
  (put 'sub '(rational rational) (lambda (x y) (tag (sub-rat x y))))
  (put 'mul '(rational rational) (lambda (x y) (tag (mul-rat x y))))
  (put 'div '(rational rational) (lambda (x y) (tag (div-rat x y))))
  (put 'equ '(rational rational) (lambda (x y) (equ-rat x y)))
  (put 'zero '(rational) (lambda (x) (if (= (denom x) 0) (error "zero division" x) (= (numer x) 0))))
  (put 'neg '(rational) (lambda (x) (make-rational (- (numer x)) (denom x))))
  (put 'make 'rational (lambda (n d) (tag (make-rat n d))))
  'done)

(define (numer x) (car x))
(define (denom x) (cdr x))
(define (make-rational n d) ((get 'make 'rational) n d))


(define (install-real-package)
  (define (tag x) (attach-tag 'real x))
  (put 'add '(real real) (lambda (x y) (tag (+ x y))))
  (put 'sub '(real real) (lambda (x y) (tag (- x y))))
  (put 'mul '(real real) (lambda (x y) (tag (* x y))))
  (put 'div '(real real) (lambda (x y) (tag (/ x y))))
  (put 'equ '(real real) (lambda (x y) (= x y)))
  (put 'zero '(real) (lambda (x) (= x 0)))
  (put 'neg '(real) (lambda (x) (make-real (- x))))
  (put 'make 'real (lambda (x) (tag x)))
  'done)

(define (make-real n) ((get 'make 'real) n))


(define (install-complex-package)
  (define pi 3.1415)
  
  (define (square x) (apply-generic 'square x))
  (put 'square '(integer) (lambda (x) (make-integer (* x x))))
  (put 'square '(rational) (lambda (x) (make-real (expt (/ (numer x) (denom x)) 2))))
  (put 'square '(real) (lambda (x) (make-real (* x x))))
  
  (define (sqrt x) (apply-generic 'sqrt x))
  (put 'sqrt '(integer) (lambda (x) (make-real (expt x 0.5))))
  (put 'sqrt '(rational) (lambda (x) (make-real (expt (/ (numer x) (denom x)) 0.5))))
  ; hard to express square root of rational number
  (put 'sqrt '(real) (lambda (x) (make-real (expt x 0.5))))
  
  (define (sine x) (apply-generic 'sin x))
  (put 'sin '(integer) (lambda (x) (make-real (sin x))))
  (put 'sin '(rational) (lambda (x) (make-real (sin (/ (numer x) (denom x))))))
  (put 'sin '(real) (lambda (x) (make-real (sin x))))

  (define (cosine x) (apply-generic 'cos x))
  (put 'cos '(integer) (lambda (x) (make-real (cos x))))
  (put 'cos '(rational) (lambda (x) (make-real (cos (/ (numer x) (denom x))))))
  (put 'cos '(real) (lambda (x) (make-real (cos x))))

  (define (arctan x) (apply-generic 'atan x))
  (put 'atan '(integer) (lambda (x) (make-real (atan x))))
  (put 'atan '(rational) (lambda (x) (make-real (atan (/ (numer x) (denom x))))))
  (put 'atan '(real) (lambda (x) (make-real (atan x))))
  
  (define (install-rectangular-package)
    (define (real-part z) (car z))
    (define (imag-part z) (cdr z))
    (define (make-from-real-imag x y) (cons x y))
    (define (magnitude z) (sqrt (+ (square (real-part z)) (square (imag-part z)))))
    (define (angle z) (atan (imag-part z) (real-part z)))
    (define (make-from-mag-ang r a) (cons (* r (cos a)) (* r (sin a))))

    (define (tag x) (attach-tag 'rectangular x))
    (put 'real-part '(rectangular) real-part)
    (put 'imag-part '(rectangular) imag-part)
    (put 'magnitude '(rectangular) magnitude)
    (put 'angle '(rectangular) angle)
    (put 'make-from-real-imag 'rectangular (lambda (x y) (tag (make-from-real-imag x y))))
    (put 'make-from-mag-ang 'rectangular (lambda (r a) (tag (make-from-mag-ang r a))))
    'done)
  
  (define (install-polar-package)
    (define (magnitude z) (car z))
    (define (angle z) (cdr z))
    (define (make-from-mag-ang r a) (cons r a))
    (define (real-part z) (* (magnitude z) (cos (angle z))))
    (define (imag-part z) (* (magnitude z) (sin (angle z))))
    (define (make-from-real-imag x y) (cons (sqrt (+ (square x) (square y))) (atan y x)))

    (define (tag x) (attach-tag 'polar x))
    (put 'real-part '(polar) real-part)
    (put 'imag-part '(polar) imag-part)
    (put 'magnitude '(polar) magnitude)
    (put 'angle '(polar) angle)
    (put 'make-from-real-imag 'polar (lambda (x y) (tag (make-from-real-imag x y))))
    (put 'make-from-mag-ang 'polar (lambda (r a) (tag (make-from-mag-ang r a))))
    'done)

  (install-rectangular-package)
  (install-polar-package)

  (define (real-part z) (apply-generic 'real-part z))
  (define (imag-part z) (apply-generic 'imag-part z))
  (define (magnitude z) (apply-generic 'magnitude z))
  (define (angle z) (apply-generic 'angle z))
  (define (make-from-real-imag x y) ((get 'make-from-real-imag 'rectangular) x y))
  (define (make-from-mag-ang r a) ((get 'make-from-mag-ang 'polar) r a))

  (define (add-complex z1 z2)
    (make-from-real-imag (add (real-part z1) (real-part z2)) (add (imag-part z1) (imag-part z2))))
  (define (sub-complex z1 z2)
    (make-from-real-imag (add (real-part z1) (real-part z2)) (add (imag-part z1) (imag-part z2))))
  (define (mul-complex z1 z2)
    (make-from-mag-ang (mul (magnitude z1) (magnitude z2)) (add (angle z1) (angle z2))))
  (define (div-complex z1 z2)
    (make-from-mag-ang (div (magnitude z1) (magnitude z2)) (sub (angle z1) (angle z2))))
  (define (equ-complex z1 z2)
    (and (and (eq? (type-tag (real-part z1)) (type-tag (real-part z2)))
              (eq? (type-tag (imag-part z1)) (type-tag (imag-part z2))))
         (and (= (contents (real-part z1)) (contents (real-part z2)))
              (= (contents (imag-part z1)) (contents (imag-part z2))))))

  (define (tag z) (attach-tag 'complex z))
  (put 'real-part '(complex) real-part)
  (put 'imag-part '(complex) imag-part)
  (put 'magnitude '(complex) magnitude)
  (put 'angle '(complex) angle)
  (put 'add '(complex complex) (lambda (z1 z2) (tag (add-complex z1 z2))))
  (put 'sub '(complex complex) (lambda (z1 z2) (tag (sub-complex z1 z2))))
  (put 'mul '(complex complex) (lambda (z1 z2) (tag (mul-complex z1 z2))))
  (put 'div '(complex complex) (lambda (z1 z2) (tag (div-complex z1 z2))))
  (put 'equ '(complex complex) (lambda (z1 z2) (equ-complex z1 z2)))
  (put 'zero '(complex) (lambda (z) (cond ((eq? 'rectangular (type-tag z)) (and (= (real-part z) 0)
                                                                                (= (imag-part z) 0)))
                                          ((eq? 'polar (type-tag z)) (= (magnitude z) 0)))))
  (put 'neg '(complex) (lambda (z) (if (eq? 'rectangular (type-tag z))
                                       (make-complex-from-real-imag (- (real-part z)) (- (imag-part z)))
                                       (make-complex-from-mag-ang (magnitude z) (+ (* 2 pi) (angle z))))))
  (put 'make-from-real-imag 'complex (lambda (x y) (tag (make-from-real-imag x y))))
  (put 'make-from-mag-ang 'complex (lambda (r a) (tag (make-from-mag-ang r a))))
  'done)

(define (real-part z) (apply-generic 'real-part z))
(define (imag-part z) (apply-generic 'imag-part z))
(define (magnitude z) (apply-generic 'magnitude z))
(define (angle z) (apply-generic 'angle z))
(define (make-complex-from-real-imag x y) ((get 'make-from-real-imag 'complex) x y))
(define (make-complex-from-mag-ang r a) ((get 'make-from-mag-ang 'complex) r a))


(define (install-raise-package)
  (define (raise-integer-to-rational n) (make-rational n 1))
  (define (raise-rational-to-real x) (make-real (/ (car x) (cdr x))))
  (define (raise-real-to-complex x) (make-complex-from-real-imag x (make-integer 0)))

  (put 'raise '(integer) raise-integer-to-rational)
  (put 'raise '(rational) raise-rational-to-real)
  (put 'raise '(real) raise-real-to-complex)
  'done)

(define (raise x) (apply-generic 'raise x))


(define (drop x)
  (let ((dropped (project x)))
    (cond ((or (eq? (type-tag x) 'polynomial) (eq? (type-tag x) 'integer)
               (eq? (type-tag (cadr x)) 'polynomial)) x)
          ((equ? x (raise dropped)) (drop dropped))
          (else x))))


(define (install-projection-package)
  (define (project-complex x) (make-real (real-part x)))
  (define (project-real x) (make-rational (round x) 1))
  (define (project-rational x)
    (if (eq? (type-tag (contents x)) 'polynomial)
        x
        (make-integer (quotient (numer x) (denom x)))))

  (put 'project '(polynomial) (lambda (x) x))
  (put 'project '(complex) project-complex)
  (put 'project '(real) project-real)
  (put 'project '(rational) project-rational)
  (put 'project '(integer) (lambda (x) x))
  'done)

(define (project x) (apply-generic 'project x))


(define (install-polynomial-package)
  (define (variable p) (car p))
  (define (term-list p) (cdr p))
  (define (variable? x) (symbol? x))
  (define (same-variable? v1 v2) (and (variable? v1) (variable? v2) (eq? v1 v2)))

  (define (adjoin-term term term-list)
    (if (=zero? (coeff term)) term-list (cons term term-list)))
  (define (the-empty-termlist) '())
  (define (first-term term-list) (car term-list))
  (define (rest-terms term-list) (cdr term-list))
  (define (empty-termlist? term-list) (null? term-list))
  (define (make-term order coeff) (list order coeff))
  (define (order term) (car term))
  (define (coeff term) (cadr term))

  (define (add-terms L1 L2)
    (cond ((empty-termlist? L1) L2)
          ((empty-termlist? L2) L1)
          (else
           (let ((t1 (first-term L1)) (t2 (first-term L2)))
             (cond ((> (order t1) (order t2)) (adjoin-term t1 (add-terms (rest-terms L1) L2)))
                   ((< (order t1) (order t2)) (adjoin-term t2 (add-terms L1 (rest-terms L2))))
                   (else (adjoin-term (make-term (order t1) (add (coeff t1) (coeff t2)))
                                      (add-terms (rest-terms L1) (rest-terms L2)))))))))
  (define (sub-terms L1 L2)
    (add-terms L1 (neg-term L2)))
  (define (mul-terms L1 L2)
    (if (empty-termlist? L1)
        (the-empty-termlist)
        (add-terms (mul-term-by-all-terms (first-term L1) L2) (mul-terms (rest-terms L1) L2))))
  (define (mul-term-by-all-terms t1 L)
    (if (empty-termlist? L)
        (the-empty-termlist)
        (let ((t2 (first-term L)))
          (adjoin-term (make-term (+ (order t1) (order t2)) (mul (coeff t1) (coeff t2)))
                       (mul-term-by-all-terms t1 (rest-terms L))))))
  (define (div-terms L1 L2)
    (if (empty-termlist? L1)
        (list (the-empty-termlist) (the-empty-termlist))
        (let ((t1 (first-term L1)) (t2 (first-term L2)))
          (if (> (order t2) (order t1))
              (list (the-empty-termlist) L1)
              (let ((new-c (div (coeff t1) (coeff t2))) (new-o (- (order t1) (order t2))))
                (let ((rest-of-result (div-terms (add-terms L1
                                                            (neg-term (mul-terms (list (make-term new-o new-c))
                                                                                 L2)))
                                                 L2)))
                  (list (adjoin-term (make-term new-o new-c) (car rest-of-result)) (cadr rest-of-result))))))))
  (define (neg-term L)
    (if (empty-termlist? L)
        (the-empty-termlist)
        (adjoin-term (make-term (order (first-term L)) (negate (coeff (first-term L))))
                     (neg-term (rest-terms L)))))
  (define (equ-terms? L1 L2)
    (cond ((and (empty-termlist? L1) (empty-termlist? L2)) true)
          ((or (empty-termlist? L1) (empty-termlist? L2)) false)
          ((not (and (= (order (first-term L1)) (order (first-term L2)))
                     (equ? (coeff (first-term L1)) (coeff (first-term L2))))) false)
          (else (equ-terms? (rest-terms L1) (rest-terms L2)))))
  (define (gcd-terms a b)
    (if (empty-termlist? b)
        a
        (gcd-terms b (remainder-terms a b))))
  (define (remainder-terms a b)
    (cadr (div-terms a b)))
  
  (define (add-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1) (add-terms (term-list p1) (term-list p2)))
        (error "Polys not in same var -- ADD-POLY" (list p1 p2))))
  (define (sub-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1) (sub-terms (term-list p1) (term-list p2)))
        (error "Polys not in same var -- SUB-POLY" (list p1 p2))))
  (define (mul-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1) (mul-terms (term-list p1) (term-list p2)))
        (error "Polys not in same var -- MUL-POLY" (list p1 p2))))
  (define (div-poly p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (make-poly (variable p1) (div-terms (term-list p1) (term-list p2)))
        (error "Polys not in same var -- DIV-POLY" (list p1 p2))))
  (define (neg-poly p)
    (make-poly (variable p) (neg-term (term-list p))))
  (define (equ-poly? p1 p2)
    (if (same-variable? (variable p1) (variable p2))
        (equ-terms? (term-list p1) (term-list p2))
        (error "Polys not in same var -- EQU-POLY?" (list p1 p2))))
  (define (gcd-poly a b)
    (if (same-variable? (variable a) (variable b))
        (make-poly (variable a) (gcd-terms (term-list a) (term-list b)))
        (error "Polys not in same var -- GCD-POLY" (list p1 p2))))
  (define (make-poly variable term-list) (cons variable term-list))

  (define (tag p) (attach-tag 'polynomial p))
  (put 'add '(polynomial polynomial) (lambda (p1 p2) (tag (add-poly p1 p2))))
  (put 'sub '(polynomial polynomial) (lambda (p1 p2) (tag (sub-poly p1 p2))))
  (put 'mul '(polynomial polynomial) (lambda (p1 p2) (tag (mul-poly p1 p2))))
  (put 'div '(polynomial polynomial) (lambda (p1 p2) (tag (div-poly p1 p2))))
  (put 'zero '(polynomial) (lambda (p) (empty-termlist? (term-list p))))
  (put 'neg '(polynomial) (lambda (p) (tag (neg-poly p))))
  (put 'equ '(polynomial polynomial) equ-poly?)
  (put 'gcd '(polynomial polynomial) (lambda (a b) (tag (gcd-poly a b))))
  (put 'make 'polynomial (lambda (var terms) (tag (make-poly var terms))))
  'done)

(define (make-polynomial var terms) ((get 'make 'polynomial) var terms))


(define (add x y) (apply-generic 'add x y))
(define (sub x y) (apply-generic 'sub x y))
(define (mul x y) (apply-generic 'mul x y))
(define (div x y) (apply-generic 'div x y))
(define (equ? x y) (apply-generic 'equ x y))
(define (=zero? x) (apply-generic 'zero x))
(define (negate x) (apply-generic 'neg x))
(define (greatest-common-divisor a b) (apply-generic 'gcd a b))


(install-integer-package)
(install-rational-package)
(install-real-package)
(install-complex-package)
(install-raise-package)
(install-projection-package)
(install-polynomial-package)

(define p1 (make-polynomial 'x '((2 1)(0 -1))))
(define p2 (make-polynomial 'x '((3 1)(0 -1))))
(define rf (make-rational p2 p1))

(greatest-common-divisor p2 p1)
(greatest-common-divisor p2 p2)
(greatest-common-divisor 204 40)