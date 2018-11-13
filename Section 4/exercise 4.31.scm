#lang sicp
(define apply-in-underlying-scheme apply)

(define (lazy? exp) (and (pair? exp) (eq? (cadr exp) 'lazy)))
(define (lazy-memo? exp) (and (pair? exp) (eq? (cadr exp) 'lazy-memo)))

(define (evaln exp env)
  (cond ((or (lazy? exp) (lazy-memo? exp)) exp)
        ((self-evaluating? exp) exp)
        ((variable? exp) (lookup-variable-value exp env))
        ((quoted? exp) (text-of-quotation exp))
        ((assignment? exp) (eval-assignment exp env))
        ((definition? exp) (eval-definition exp env))
        ((if? exp) (eval-if exp env))
        ((lambda? exp) (make-procedure (lambda-parameters exp) (lambda-body exp) env))
        ((begin? exp) (eval-sequence (begin-actions exp) env))
        ((cond? exp) (evaln (cond->if exp) env))
        (else (applyn (actual-value (operator exp) env) (operands exp) env))))

(define (actual-value exp env)
  (force-it (evaln exp env)))


(define (applyn procedure arguments env)
  (cond ((primitive-procedure? procedure) (apply-primitive-procedure procedure
                                                                     (list-of-arg-values arguments env)))
        ((compound-procedure? procedure)
         (eval-sequence (procedure-body procedure)
                        (extend-environment (extract-parameters (procedure-parameters procedure))
                                            (list-of-args (procedure-parameters procedure) arguments env)
                                            (procedure-environment procedure))))
        (else (error "Unknown procedure type -- APPLY" procedure))))
(define (extract-parameters vars)
  (cond ((null? vars) '())
        ((or (lazy? (car vars)) (lazy-memo? (car vars))) (cons (caar vars) (extract-parameters (cdr vars))))
        (else (cons (car vars) (extract-parameters (cdr vars))))))

(define (list-of-arg-values exps env)
  (if (no-operands? exps)
      '()
      (cons (actual-value (first-operand exps) env)
            (list-of-arg-values (rest-operands exps) env))))
(define (list-of-args para exps env)
  (if (no-operands? exps)
      '()
      (cons (cond ((lazy? (car para)) (delay-it (list (car exps) 'lazy) env))
                  ((lazy-memo? (car para)) (delay-it (list (car exps) 'lazy-memo) env))
                  (else (evaln (car exps) env)))
            (list-of-args (cdr para) (cdr exps) env))))


(define (delay-it exp env)
  (if (thunk? exp)
      exp
      (list 'thunk exp env)))
(define (thunk? obj)
  (tagged-list? obj 'thunk))
(define (thunk-exp thunk)
  (if (or (lazy? (cadr thunk)) (lazy-memo? (cadr thunk)))
      (caadr thunk)
      (cadr thunk)))
(define (thunk-env thunk) (caddr thunk))

(define (evaluated-thunk? obj)
  (tagged-list? obj 'evaluated-thunk))
(define (thunk-value evaluated-thunk) (cadr evaluated-thunk))
(define (force-it obj)
  (cond ((thunk? obj) (cond ((lazy-memo? (cadr obj)) (let ((result (actual-value (thunk-exp obj)
                                                                                 (thunk-env obj))))
                                                       (set-car! obj 'evaluated-thunk)
                                                       (set-car! (cdr obj) result)
                                                       (set-cdr! (cdr obj) '())
                                                       result))
                            ((lazy? (cadr obj)) (actual-value (thunk-exp obj) (thunk-env obj)))
                            (else (thunk-exp obj))))
        ((evaluated-thunk? obj) (thunk-value obj))
        (else obj)))
  


(define (eval-if exp env)
  (if (true? (actual-value (if-predicate exp) env))
      (evaln (if-consequent exp) env)
      (evaln (if-alternative exp) env)))

(define (eval-sequence exps env)
  (cond ((last-exp? exps) (evaln (first-exp exps) env))
        (else (evaln (first-exp exps) env)
              (eval-sequence (rest-exps exps) env))))

(define (eval-assignment exp env)
  (set-variable-value! (assignment-variable exp)
                       (evaln (assignment-value exp) env)
                       env)
  'ok)

(define (eval-definition exp env)
  (define-variable! (definition-variable exp)
    (evaln (definition-value exp) env)
    env)
  'ok)


(define (self-evaluating? exp)
  (cond ((number? exp) true)
        ((string? exp) true)
        (else false)))


(define (variable? exp) (symbol? exp))


(define (quoted? exp)
  (tagged-list? exp 'quote))

(define (text-of-quotation exp) (cadr exp))

(define (tagged-list? exp tag)
  (if (pair? exp)
      (eq? (car exp) tag)
      false))


(define (assignment? exp)
  (tagged-list? exp 'set!))

(define (assignment-variable exp) (cadr exp))
(define (assignment-value exp) (caddr exp))


(define (definition? exp)
  (tagged-list? exp 'define))

(define (definition-variable exp)
  (if (symbol? (cadr exp))
      (cadr exp)
      (caadr exp)))

(define (definition-value exp)
  (if (symbol? (cadr exp))
      (caddr exp)
      (make-lambda (cdadr exp)
                   (cddr exp))))


(define (lambda? exp) (tagged-list? exp 'lambda))

(define (lambda-parameters exp) (cadr exp))
(define (lambda-body exp) (cddr exp))

(define (make-lambda parameters body)
  (cons 'lambda (cons parameters body)))


(define (if? exp) (tagged-list? exp 'if))

(define (if-predicate exp) (cadr exp))
(define (if-consequent exp) (caddr exp))
(define (if-alternative exp)
  (if (not (null? (cdddr exp)))
      (cadddr exp)
      'false))

(define (make-if predicate consequent alternative)
  (list 'if predicate consequent alternative))


(define (begin? exp) (tagged-list? exp 'begin))

(define (begin-actions exp) (cdr exp))
(define (last-exp? seq) (null? (cdr seq)))
(define (first-exp seq) (car seq))
(define (rest-exps seq) (cdr seq))

(define (sequence->exp seq)
  (cond ((null? seq) seq)
        ((last-exp? seq) (first-exp seq))
        (else (make-begin seq))))
(define (make-begin seq) (cons 'begin seq))


(define (application? exp) (pair? exp))

(define (operator exp) (car exp))
(define (operands exp) (cdr exp))
(define (no-operands? ops) (null? ops))
(define (first-operand ops) (car ops))
(define (rest-operands ops) (cdr ops))


(define (cond? exp) (tagged-list? exp 'cond))

(define (cond-clauses exp) (cdr exp))
(define (cond-else-clause? clause)
  (eq? (cond-predicate clause) 'else))
(define (cond-predicate clause) (car clause))
(define (cond-actions clause) (cdr clause))
(define (cond->if exp)
  (expand-clauses (cond-clauses exp)))
(define (cond-recipient? clause) (eq? (cadr clause) '=>))
(define (cond-recipient clause) (caddr clause))
(define (expand-clauses clauses)
  (if (null? clauses)
      'false
      (let ((first (car clauses))
            (rest (cdr clauses)))
        (if (cond-else-clause? first)
            (if (null? rest)
                (sequence->exp (cond-actions first))
                (error "ELSE clause isn't last -- COND->IF" clauses))
            (make-if (cond-predicate first)
                     (if (cond-recipient? first)
                         (cons (cond-recipient first) (cond-predicate first))
                         (sequence->exp (cond-actions first)))
                     (expand-clauses rest))))))


(define (true? x)
  (not (eq? x false)))
(define (false? x)
  (eq? x false))


(define (primitive-procedure? proc)
  (tagged-list? proc 'primitive))
(define (primitive-implementation proc) (cadr proc))
(define primitive-procedures
  (list (list 'car car) (list 'cdr cdr)
        (list 'caar caar) (list 'cadr cadr) (list 'cddr cddr)
        (list 'caaar caaar) (list 'caadr caadr) (list 'cdaar cdaar) (list 'cadar cadar)
        (list 'caddr caddr) (list 'cdadr cdadr) (list 'cddar cddar) (list 'cdddr cdddr)
        (list 'cons cons) (list 'list list)
        (list 'null? null?) (list 'pair? pair?) (list 'number? number?) (list 'string? string?)
        (list 'newline newline) (list 'display display)
        (list 'square (lambda (x) (* x x))) (list 'cube (lambda (x) (* x x x))) (list 'sqrt sqrt)
        (list '+ +) (list '- -) (list '* *) (list '/ /) (list '= =)
        (list 'remainder remainder) (list 'modulo modulo) (list 'quotient quotient)
        (list 'abs abs) (list 'inc inc) (list 'dec dec)
        (list 'gcd gcd) (list 'lcm lcm)
        (list 'exp exp) (list 'expt expt) (list 'log log)
        (list 'sin sin) (list 'cos cos) (list 'tan tan)
        (list 'asin asin) (list 'acos acos) (list 'atan atan)
        (list 'floor floor) (list 'ceiling ceiling) (list 'truncate truncate) (list 'round round)
        (list 'map map)))
(define (primitive-procedure-names)
  (map car primitive-procedures))
(define (primitive-procedure-objects)
  (map (lambda (proc) (list 'primitive (cadr proc))) primitive-procedures))

(define (apply-primitive-procedure proc args)
  (apply-in-underlying-scheme (primitive-implementation proc) args))


(define (compound-procedure? p)
  (tagged-list? p 'procedure))

(define (procedure-parameters p) (cadr p))
(define (procedure-body p) (caddr p))
(define (procedure-environment p) (cadddr p))

(define (make-procedure parameters body env)
  (list 'procedure parameters body env))


(define (enclosing-environment env) (cdr env))
(define (first-frame env) (car env))
(define the-empty-environment '())
(define (make-frame variables values)
  (cons variables values))
(define (frame-variables frame) (car frame))
(define (frame-values frame) (cdr frame))
(define (add-binding-to-frame! var val frame)
  (set-car! frame (cons var (car frame)))
  (set-cdr! frame (cons val (cdr frame))))

(define (lookup-variable-value var env)
  (define (env-loop env)
    (define (scan vars vals)
      (cond ((null? vars) (env-loop (enclosing-environment env)))
            ((eq? var (car vars)) (if (eq? (car vals) '*unassigned*)
                                      (error "Variable is not yet assigned" (car vars))
                                      (car vals)))
            (else (scan (cdr vars) (cdr vals)))))
    (if (eq? env the-empty-environment)
        (error "Unbound variable" var)
        (let ((frame (first-frame env)))
          (scan (frame-variables frame)
                (frame-values frame)))))
  (env-loop env))

(define (extend-environment vars vals base-env)
  (if (= (length vars) (length vals))
      (cons (make-frame vars vals) base-env)
      (if (< (length vars) (length vals))
          (error "Too many arguments supplied" vars vals)
          (error "too few arguments supplied" vars vals))))
(define (define-variable! var val env)
  (let ((frame (first-frame env)))
    (define (scan vars vals)
      (cond ((null? vars) (add-binding-to-frame! var val frame))
            ((eq? var (car vars)) (set-car! vals val))
            (else (scan (cdr vars) (cdr vals)))))
    (scan (frame-variables frame)
          (frame-values frame))))
(define (set-variable-value! var val env)
  (define (env-loop env)
    (define (scan vars vals)
      (cond ((null? vars) (env-loop (enclosing-environment env)))
            ((eq? var (car vars)) (set-car! vals val))
            (else (scan (cdr vars) (cdr vals)))))
    (if (eq? env the-empty-environment)
        (error "Unbound variable -- SET!" var)
        (let ((frame (first-frame env)))
          (scan (frame-variables frame)
                (frame-values frame)))))
  (env-loop env))

(define (setup-environment)
  (let ((initial-env (extend-environment (primitive-procedure-names) (primitive-procedure-objects)
                                         the-empty-environment)))
    (define-variable! 'true true initial-env)
    (define-variable! 'false false initial-env)
    initial-env))
(define the-global-environment (setup-environment))


(define input-prompt ";;; L-Eval input:")
(define output-prompt ";;; L-Eval value:")
(define (driver-loop)
  (prompt-for-input input-prompt)
  (let ((input (read)))
    (let ((output (actual-value input the-global-environment)))
      (announce-output output-prompt)
      (user-print output)))
  (driver-loop))
(define (prompt-for-input string)
  (newline) (newline) (display string) (newline))
(define (announce-output string)
  (newline) (display string) (newline))
(define (user-print object)
  (if (compound-procedure? object)
      (display (list 'compound-procedure
                     (procedure-parameters object)
                     (procedure-body object)
                     '<procedure-env>))
      (display object)))


(driver-loop)