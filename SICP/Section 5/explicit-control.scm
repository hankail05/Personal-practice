#lang sicp
(define apply-in-underlying-scheme apply)
(define (evaln exp env)
  (cond ((self-evaluating? exp) exp)
        ((variable? exp) (lookup-variable-value exp env))
        ((quoted? exp) (text-of-quotation exp))
        ((assignment? exp) (eval-assignment exp env))
        ((definition? exp) (eval-definition exp env))
        ((if? exp) (eval-if exp env))
        ((lambda? exp) (make-procedure (lambda-parameters exp) (lambda-body exp) env))
        ((begin? exp) (eval-sequence (begin-actions exp) env))
        ((cond? exp) (evaln (cond->if exp) env))
        ((and? exp) (eval-and exp env))
        ((or? exp) (eval-or exp env))
        ((let? exp) (evaln (let->combination exp) env))
        ((let*? exp) (evaln (let*->nested-lets exp) env)) ; enough.
        ((letrec? exp) (evaln (letrec->let exp) env))
        ((application? exp) (applyn (evaln (operator exp) env) (list-of-values (operands exp) env)))
        (else (error "Unknown expression type -- EVAL" exp))))


(define (applyn procedure arguments)
  (cond ((primitive-procedure? procedure) (apply-primitive-procedure procedure arguments))
        ((compound-procedure? procedure) (eval-sequence (procedure-body procedure)
                                                        (extend-environment (procedure-parameters procedure)
                                                                            arguments
                                                                            (procedure-environment procedure))))
        (else (error "Unknown expression type -- APPLY" procedure))))

(define (list-of-values exps env)
  (if (no-operands? exps)
      '()
      (cons (evaln (first-operand exps) env)
            (list-of-values (rest-operands exps) env))))


(define (eval-if exp env)
  (if (true? (evaln (if-predicate exp) env))
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


(define (and-clauses exp) (cdr exp))
(define (or-clauses exp) (cdr exp))
(define (null-exp? exp) (null? exp))

(define (and? exp)
  (tagged-list? exp 'and))

(define (eval-and exp env)
  (if (null-exp? exp)
      false
      (let ((first (first-exp exp))
            (rest (rest-exps exp)))
        (cond ((last-exp? exp) first)
              (first (eval-and rest env))
              (else false)))))

(define (or? exp)
  (tagged-list? exp 'or))

(define (eval-or exp env)
  (if (null-exp? exp)
      false
      (let ((first (first-exp exp))
            (rest (rest-exps exp)))
        (cond ((last-exp? exp) first)
              (first true)
              (else (eval-or rest env))))))

(define (and->if exp)
  (expand-and-clauses (and-clauses exp)))
(define (expand-and-clauses exp)
  (let ((first (first-exp exp))
        (rest (rest-exps exp)))
    (cond ((null-exp? exp) false)
          ((last-exp? exp) first)
          (else (make-if (cond-predicate first)
                         (and->if rest)
                         false)))))
(define (or->if exp)
  (expand-clauses (or-clauses exp)))
(define (expand-or-clauses exp)
  (let ((first (first-exp exp))
        (rest (rest-exps exp)))
    (cond ((null-exp? exp) false)
          ((last-exp? exp) first)
          (else (make-if (cond-predicate first)
                         true
                         (or->if rest))))))


(define (let? exp)
  (tagged-list? exp 'let))

(define (let-variables clauses)
  (map car (car clauses)))
(define (let-expressions clauses)
  (map cadr (car clauses)))
(define (let-body clauses) (cdr clauses))

(define (named-let? exp) (and (let? exp) (symbol? (cadr exp))))

(define (named-let-variable clauses) (car clauses))
(define (named-let-parameters clauses)
  (define (iter bindings) 
    (if (null? bindings)
        nil
        (cons (caar bindings)
              (iter (cdr bindings)))))
  (iter (cadr clauses)))
(define (named-let-arguments clauses)
  (define (iter bindings)
    (if (null? bindings)
        nil
        (cons (cadar bindings)
              (iter (cdr bindings)))))
  (iter (cadr clauses)))
(define (named-let-body clauses) (cddr clauses))
(define (named-let->combination exp)
  (let ((clauses (cdr exp)))
    (make-begin (list (list 'define
                            (named-let-variable clauses)
                            (make-lambda (named-let-parameters clauses)
                                         (named-let-body clauses)))
                      (cons (named-let-variable clauses)
                            (named-let-arguments clauses))))))
(define (let->combination exp)
  (let ((clauses (cdr exp)))
    (if (named-let? clauses)
        (named-let->combination exp)
        (cons (make-lambda (let-variables clauses)
                           (let-body clauses))
              (let-expressions clauses)))))


(define (let*? exp)
  (tagged-list? exp 'let*))

(define (let*-null? clauses) (null? clauses))
(define (let*-expression clauses) (car clauses))
(define (let*-rest-expressions clauses) (cdr clauses))
(define (let*-body exp) (caddr exp))
(define (let*->nested-lets exp)
  (define (iter clauses)
    (if (let*-null? clauses)
        (sequence->exp (let*-body exp))
        (list 'let (list (let*-expression clauses)) (iter (let*-rest-expressions clauses)))))
  (iter (cadr exp)))


(define (letrec? exp) (tagged-list? exp 'letrec))

(define (letrec-variables exp) (map car (cadr exp)))
(define (letrec-expressions exp) (map cadr (cadr exp)))
(define (make-variables variables)
  (if (null? variables)
      nil
      (cons (list (car variables) ''*unattached)
            (make-variables (cdr variables)))))
(define (set-variables! variables expressions)
  (if (null? variables)
      nil
      (cons (list 'set! (car variables) (car expressions))
            (set-variables! (cdr variables) (cdr expressions)))))
(define (letrec-body exp) (cddr exp))
(define (letrec->let exp)
  (list 'let
        (make-variables (letrec-variables exp))
        (make-begin (append (set-variables! (letrec-variables exp) (letrec-expressions exp))
                            (letrec-body exp)))))


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
  (list 'procedure parameters (scan-out-defines body) env))


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
  (let ((initial-env (extend-environment (primitive-procedure-names)
                                         (primitive-procedure-objects)
                                         the-empty-environment)))
    (define-variable! 'true true initial-env)
    (define-variable! 'false false initial-env)
    initial-env))
(define the-global-environment (setup-environment))


(define input-prompt ";;; M-Eval input:")
(define output-prompt ";;; M-Eval value:")
(define (driver-loop)
  (prompt-for-input input-prompt)
  (let ((input (read)))
    (let ((output (evaln input the-global-environment)))
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


(define (scan-out-defines proc)
  (let ((body-list proc))
    (define (internal-definition-variable body-list)
      (let ((body (car body-list))
            (rest (cdr body-list)))
        (cond ((eq? body-list nil) nil)
              ((definition? body) (cons (definition-variable body)
                                        (internal-definition-variable rest)))
              (else nil))))
    (define (internal-definition-value body-list)
      (let ((body (car body-list))
            (rest (cdr body-list)))
        (cond ((eq? body-list nil) nil)
              ((definition? body) (cons (definition-value body)
                                        (internal-definition-value rest)))
              (else nil))))
    (define (initial-variables variables)
      (if (null? variables)
          nil
          (cons (list (car variables) ''*unassigned*)
                (initial-variables (cdr variables)))))
    (define (set-variables! variables values)
      (if (null? variables)
          nil
          (cons (list 'set! (car variables) (car values))
                (set-variables! (cdr variables) (cdr values)))))
    (define (true-body body-list)
      (cond ((null? body-list) body-list)
            ((definition? (car body-list)) (true-body (cdr body-list)))
            (else body-list)))
    (let ((variables (internal-definition-variable body-list)))
      (if (null? variables)
          body-list
          (list (list 'let
                      (initial-variables variables)
                      (make-begin (append (set-variables! (internal-definition-variable body-list)
                                                          (internal-definition-value body-list))
                                          (true-body body-list)))))))))


(define (make-machine register-names ops controller-text)
  (let ((machine (make-new-machine)))
    (for-each (lambda (register-name)
                ((machine 'allocate-register) register-name))
              register-names)
    ((machine 'install-operations) ops)
    ((machine 'install-instruction-sequence) (assemble controller-text machine))
    machine))

(define (make-register name)
  (let ((contents '*unassigned*))
    (define (dispatch message)
      (cond ((eq? message 'get) contents)
            ((eq? message 'set) (lambda (value) (set! contents value)))
            (else (error "Unknown request -- REGISTER" message))))
    dispatch))
(define (get-contents register)
  (register 'get))
(define (set-contents! register value)
  ((register 'set) value))

(define (make-stack)
  (let ((s '())
        (number-pushes 0)
        (max-depth 0)
        (current-depth 0))
    (define (push x)
      (set! s (cons x s))
      (set! number-pushes (+ 1 number-pushes))
      (set! current-depth (+ 1 current-depth))
      (set! max-depth (max current-depth max-depth)))
    (define (pop)
      (if (null? s)
          (error "Empty stack -- POP")
          (let ((top (car s)))
            (set! s (cdr s))
            (set! current-depth (- current-depth 1))
            top)))
    (define (initialize)
      (set! s '())
      (set! number-pushes 0)
      (set! max-depth 0)
      (set! current-depth 0)
      'done)
    (define (print-statistics)
      (newline)
      (display (list 'total-pushes '= number-pushes
                     'maximum-depth '= max-depth)))
    (define (dispatch message)
      (cond ((eq? message 'push) push)
            ((eq? message 'pop) (pop))
            ((eq? message 'initialize) (initialize))
            ((eq? message 'print-statistics) (print-statistics))
            (else (error "Unknown request -- STACK" message))))
    dispatch))
(define (pop stack) (stack 'pop))
(define (push stack value) ((stack 'push) value))

(define (make-new-machine)
  (let ((pc (make-register 'pc))
        (flag (make-register 'flag))
        (stack (make-stack)))
    (let ((the-instruction-sequence '())
          (the-ops (list (list 'initialize-stack (lambda () (stack 'initialize)))
                         (list 'print-stack-statistics (lambda () (stack 'print-statistics)))))
          (register-table (list (list 'pc pc) (list 'flag flag))))
      (define (allocate-register name)
        (if (assoc name register-table)
            (error "Multiply defined register: " name)
            (set! register-table (cons (list name (make-register name)) register-table)))
        'register-allocated)
      (define (lookup-register name)
        (let ((val (assoc name register-table)))
          (if val
              (cadr val)
              (error "Unknown register:" name))))
      (define (execute)
        (let ((insts (get-contents pc)))
          (if (null? insts)
              'done
              (begin ((instruction-execution-proc (car insts)))
                     (execute)))))
      (define (dispatch message)
        (cond ((eq? message 'start) (set-contents! pc the-instruction-sequence)
                                    (execute))
              ((eq? message 'install-instruction-sequence) (lambda (seq) (set! the-instruction-sequence seq)))
              ((eq? message 'allocate-register) allocate-register)
              ((eq? message 'get-register) lookup-register)
              ((eq? message 'install-operations) (lambda (ops) (set! the-ops (append the-ops ops))))
              ((eq? message 'stack) stack)
              ((eq? message 'operations) the-ops)
              (else (error "Unknown request -- MACHINE" message))))
      dispatch)))
(define (start machine)
  (machine 'start))
(define (get-register-contents machine register-name)
  (get-contents (get-register machine register-name)))
(define (set-register-contents! machine register-name value)
  (set-contents! (get-register machine register-name) value)
  'done)
(define (get-register machine reg-name)
  ((machine 'get-register) reg-name))


(define (assemble controller-text machine)
  (extract-labels controller-text
                  (lambda (insts labels)
                    (update-insts! insts labels machine)
                    insts)))

(define (extract-labels text receive)
  (if (null? text)
      (receive '() '())
      (extract-labels (cdr text)
                      (lambda (insts labels)
                        (let ((next-inst (car text)))
                          (if (symbol? next-inst)
                              (receive insts
                                       (cons (make-label-entry next-inst insts) labels))
                              (receive (cons (make-instruction next-inst) insts)
                                       labels)))))))

(define (update-insts! insts labels machine)
  (let ((pc (get-register machine 'pc))
        (flag (get-register machine 'flag))
        (stack (machine 'stack))
        (ops (machine 'operations)))
    (for-each (lambda (inst)
                (set-instruction-execution-proc! inst
                                                 (make-execution-procedure (instruction-text inst) labels machine pc flag stack ops)))
              insts)))

(define (make-instruction text) (cons text '()))
(define (instruction-text inst) (car inst))
(define (instruction-execution-proc inst) (cdr inst))
(define (set-instruction-execution-proc! inst proc) (set-cdr! inst proc))
(define (make-label-entry label-name insts) (cons label-name insts))

(define (lookup-label labels label-name)
  (let ((val (assoc label-name labels)))
    (if val
        (cdr val)
        (error "Undefined label -- ASSEMBLE" label-name))))


(define (make-execution-procedure inst labels machine pc flag stack ops)
  (cond ((eq? (car inst) 'assign) (make-assign inst machine labels ops pc))
        ((eq? (car inst) 'test) (make-test inst machine labels ops flag pc))
        ((eq? (car inst) 'branch) (make-branch inst machine labels flag pc))
        ((eq? (car inst) 'goto) (make-goto inst machine labels pc))
        ((eq? (car inst) 'save) (make-save inst machine stack pc))
        ((eq? (car inst) 'restore) (make-restore inst machine stack pc))
        ((eq? (car inst) 'perform) (make-perform inst machine labels ops pc))
        (else (error "Unknown instruction type -- ASSEMBLE" inst))))

(define (make-assign inst machine labels operations pc)
  (let ((target (get-register machine (assign-reg-name inst)))
        (value-exp (assign-value-exp inst)))
    (let ((value-proc (if (operation-exp? value-exp)
                          (make-operation-exp value-exp machine labels operations)
                          (make-primitive-exp (car value-exp) machine labels))))
      (lambda ()
        (set-contents! target (value-proc))
        (advance-pc pc)))))
(define (assign-reg-name assign-instruction) (cadr assign-instruction))
(define (assign-value-exp assign-instruction) (cddr assign-instruction))

(define (advance-pc pc) (set-contents! pc (cdr (get-contents pc))))

(define (make-test inst machine labels operations flag pc)
  (let ((condition (test-condition inst)))
    (if (operation-exp? condition)
        (let ((condition-proc (make-operation-exp condition machine labels operations)))
          (lambda ()
            (set-contents! flag (condition-proc))
            (advance-pc pc)))
        (error "Bad TEST instruction -- ASSEMBLE" inst))))
(define (test-condition test-instruction) (cdr test-instruction))

(define (make-branch inst machine labels flag pc)
  (let ((dest (branch-dest inst)))
    (if (label-exp? dest)
        (let ((insts (lookup-label labels (label-exp-label dest))))
          (lambda ()
            (if (get-contents flag)
                (set-contents! pc insts)
                (advance-pc pc))))
        (error "Bad BRANCH instruction -- ASSEMBLE" inst))))
(define (branch-dest branch-instruction) (cadr branch-instruction))

(define (make-goto inst machine labels pc)
  (let ((dest (goto-dest inst)))
    (cond ((label-exp? dest) (let ((insts (lookup-label labels (label-exp-label dest))))
                               (lambda () (set-contents! pc insts))))
          ((register-exp? dest) (let ((reg (get-register machine (register-exp-reg dest))))
                                  (lambda ()
                                    (set-contents! pc (get-contents reg)))))
          (else (error "Bad GOTO instruction -- ASSEMBLE" inst)))))
(define (goto-dest goto-instruction) (cadr goto-instruction))

(define (make-save inst machine stack pc)
  (let ((reg (get-register machine (stack-inst-reg-name inst))))
    (lambda ()
      (push stack (get-contents reg))
      (advance-pc pc))))
(define (make-restore inst machine stack pc)
  (let ((reg (get-register machine (stack-inst-reg-name inst))))
    (lambda ()
      (set-contents! reg (pop stack))
      (advance-pc pc))))
(define (stack-inst-reg-name stack-instruction) (cadr stack-instruction))

(define (make-perform inst machine labels operations pc)
  (let ((action (perform-action inst)))
    (if (operation-exp? action)
        (let ((action-proc (make-operation-exp action machine labels operations)))
          (lambda ()
            (action-proc)
            (advance-pc pc)))
        (error "Bad PERFORM instruction -- ASSEMBLE" inst))))
(define (perform-action inst) (cdr inst))


(define (make-primitive-exp exp machine labels)
  (cond ((constant-exp? exp) (let ((c (constant-exp-value exp)))
                               (lambda () c)))
        ((label-exp? exp) (let ((insts (lookup-label labels (label-exp-label exp))))
                            (lambda () insts)))
        ((register-exp? exp) (let ((r (get-register machine (register-exp-reg exp))))
                               (lambda () (get-contents r))))
        (else (error "Unknown expression type -- ASSEMBLE" exp))))
(define (register-exp? exp) (tagged-list? exp 'reg))
(define (register-exp-reg exp) (cadr exp))
(define (constant-exp? exp) (tagged-list? exp 'const))
(define (constant-exp-value exp) (cadr exp))
(define (label-exp? exp) (tagged-list? exp 'label))
(define (label-exp-label exp) (cadr exp))


(define (make-operation-exp exp machine labels operations)
  (let ((op (lookup-prim (operation-exp-op exp) operations))
        (aprocs (map (lambda (e) (make-primitive-exp e machine labels))
                     (operation-exp-operands exp))))
    (lambda ()
      (apply op (map (lambda (p) (p)) aprocs)))))
(define (operation-exp? exp) (and (pair? exp) (tagged-list? (car exp) 'op)))
(define (operation-exp-op operation-exp) (cadr (car operation-exp)))
(define (operation-exp-operands operation-exp) (cdr operation-exp))

(define (lookup-prim symbol operations)
  (let ((val (assoc symbol operations)))
    (if val
        (cadr val)
        (error "Unknown operation -- ASSEMBLE" symbol))))


(define (empty-arglist) '())
(define (adjoin-arg arg arglist)
  (append arglist (list arg)))
(define (last-operand? ops)
  (null? (cdr ops)))
(define (no-more-exps? seq) (null? seq))
(define (get-global-environment) the-global-environment)


(define eceval-operations
  (list (list 'read read)
        (list 'self-evaluating? self-evaluating?)
        (list 'quoted? quoted?)
        (list 'text-of-quotation text-of-quotation)
        (list 'variable? variable?)
        (list 'assignment? assignment?)
        (list 'assignment-variable assignment-variable)
        (list 'assignment-value assignment-value)
        (list 'definition? definition?)
        (list 'definition-variable definition-variable)
        (list 'definition-value definition-value)
        (list 'lambda? lambda?)
        (list 'lambda-parameters lambda-parameters)
        (list 'lambda-body lambda-body)
        (list 'if? if?)
        (list 'if-predicate if-predicate)
        (list 'if-consequent if-consequent)
        (list 'if-alternative if-alternative)
        (list 'begin? begin?)
        (list 'begin-actions begin-actions)
        (list 'last-exp? last-exp?)
        (list 'first-exp first-exp)
        (list 'rest-exps rest-exps)
        (list 'application? application?)
        (list 'operator operator)
        (list 'operands operands)
        (list 'no-operands? no-operands?)
        (list 'first-operand first-operand)
        (list 'rest-operands rest-operands)
        (list 'true? true?)
        (list 'make-procedure make-procedure)
        (list 'compound-procedure? compound-procedure?)
        (list 'procedure-parameters procedure-parameters)
        (list 'procedure-body procedure-body)
        (list 'procedure-environment procedure-environment)
        (list 'extend-environment extend-environment)
        (list 'lookup-variable-value lookup-variable-value)
        (list 'set-variable-value! set-variable-value!)
        (list 'define-variable! define-variable!)
        (list 'primitive-procedure? primitive-procedure?)
        (list 'apply-primitive-procedure apply-primitive-procedure)
        (list 'prompt-for-input prompt-for-input)
        (list 'announce-output announce-output)
        (list 'user-print user-print)
        (list 'empty-arglist empty-arglist)
        (list 'adjoin-arg adjoin-arg)
        (list 'last-operand? last-operand?)
        (list 'no-more-exps? no-more-exps?)
        (list 'get-global-environment get-global-environment)))

(define eceval
  (make-machine '(exp env val proc argl continue unev)
                eceval-operations
                '(read-eval-print-loop
                  (perform (op initialize-stack))
                  (perform (op prompt-for-input) (const ";;; EC-Eval input:"))
                  (assign exp (op read))
                  (assign env (op get-global-environment))
                  (assign continue (label print-result))
                  (goto (label eval-dispatch))
                  
                  print-result
                  (perform (op print-stack-statistics))
                  (perform (op announce-output) (const ";;; EC-Eval value:"))
                  (perform (op user-print) (reg val))
                  (goto (label read-eval-print-loop))

                  unknown-expression-type
                  (assign val (const unknown-expression-type-error))
                  (goto (label signal-error))

                  unknown-procedure-type
                  (restore continue)
                  (assign val (const unknown-procedure-type-error))
                  (goto (label signal-error))

                  signal-error
                  (perform (op user-print) (reg val))
                  (goto (label read-eval-print-loop))
                  
                  eval-dispatch
                  (test (op self-evaluating?) (reg exp))
                  (branch (label ev-self-eval))
                  (test (op variable?) (reg exp))
                  (branch (label ev-variable))
                  (test (op quoted?) (reg exp))
                  (branch (label ev-quoted))
                  (test (op assignment?) (reg exp))
                  (branch (label ev-assignment))
                  (test (op definition?) (reg exp))
                  (branch (label ev-definition))
                  (test (op if?) (reg exp))
                  (branch (label ev-if))
                  (test (op lambda?) (reg exp))
                  (branch (label ev-lambda))
                  (test (op begin?) (reg exp))
                  (branch (label ev-begin))
                  (test (op application?) (reg exp))
                  (branch (label ev-application))
                  (goto (label unknown-expression-type))

                  ev-self-eval
                  (assign val (reg exp))
                  (goto (reg continue))
    
                  ev-variable
                  (assign val (op lookup-variable-value) (reg exp) (reg env))
                  (goto (reg continue))
    
                  ev-quoted
                  (assign val (op text-of-quotation) (reg exp))
                  (goto (reg continue))
    
                  ev-lambda
                  (assign unev (op lambda-parameters) (reg exp))
                  (assign exp (op lambda-body) (reg exp))
                  (assign val (op make-procedure) (reg unev) (reg exp) (reg env))
                  (goto (reg continue))

                  ev-application
                  (save continue)
                  (save env)
                  (assign unev (op operands) (reg exp))
                  (save unev)
                  (assign exp (op operator) (reg exp))
                  (assign continue (label ev-appl-did-operator))
                  (goto (label eval-dispatch))

                  ev-appl-did-operator
                  (restore unev)
                  (restore env)
                  (assign argl (op empty-arglist))
                  (assign proc (reg val))
                  (test (op no-operands?) (reg unev))
                  (branch (label apply-dispatch))
                  (save proc)

                  ev-appl-operand-loop
                  (save argl)
                  (assign exp (op first-operand) (reg unev))
                  (test (op last-operand?) (reg unev))
                  (branch (label ev-appl-last-arg))
                  (save env)
                  (save unev)
                  (assign continue (label ev-appl-accumulate-arg))
                  (goto (label eval-dispatch))

                  ev-appl-accumulate-arg
                  (restore unev)
                  (restore env)
                  (restore argl)
                  (assign argl (op adjoin-arg) (reg val) (reg argl))
                  (assign unev (op rest-operands) (reg unev))
                  (goto (label ev-appl-operand-loop))

                  ev-appl-last-arg
                  (assign continue (label ev-appl-accum-last-arg))
                  (goto (label eval-dispatch))
    
                  ev-appl-accum-last-arg
                  (restore argl)
                  (assign argl (op adjoin-arg) (reg val) (reg argl))
                  (restore proc)
                  (goto (label apply-dispatch))

                  apply-dispatch
                  (test (op primitive-procedure?) (reg proc))
                  (branch (label primitive-apply))
                  (test (op compound-procedure?) (reg proc))
                  (branch (label compound-apply))
                  (goto (label unknown-procedure-type))

                  primitive-apply
                  (assign val (op apply-primitive-procedure) (reg proc) (reg argl))
                  (restore continue)
                  (goto (reg continue))

                  compound-apply
                  (assign unev (op procedure-parameters) (reg proc))
                  (assign env (op procedure-environment) (reg proc))
                  (assign env (op extend-environment) (reg unev) (reg argl) (reg env))
                  (assign unev (op procedure-body) (reg proc))
                  (goto (label ev-sequence))

                  ev-begin
                  (assign unev (op begin-actions) (reg exp))
                  (save continue)
                  (goto (label ev-sequence))

                  ev-sequence
                  (assign exp (op first-exp) (reg unev))
                  (test (op last-exp?) (reg unev))
                  (branch (label ev-sequence-last-exp))
                  (save unev)
                  (save env)
                  (assign continue (label ev-sequence-continue))
                  (goto (label eval-dispatch))
                  
                  ev-sequence-continue
                  (restore env)
                  (restore unev)
                  (assign unev (op rest-exps) (reg unev))
                  (goto (label ev-sequence))
                  
                  ev-sequence-last-exp
                  (restore continue)
                  (goto (label eval-dispatch))


                  ;;; Non tail-recursive sequence
                  ; ev-sequence
                  ; (test (op no-more-exps?) (reg unev))
                  ; (branch (label ev-sequence-end))
                  ; (assign exp (op first-exp) (reg unev))
                  ; (save unev)
                  ; (save env)
                  ; (assign continue (label ev-sequence-continue))
                  ; (goto (label eval-dispatch))
    
                  ; ev-sequence-continue
                  ; (restore env)
                  ; (restore unev)
                  ; (assign unev (op rest-exps) (reg unev))
                  ; (goto (label ev-sequence))
    
                  ; ev-sequence-end
                  ; (restore continue)
                  ; (goto (reg continue))

                  ev-if
                  (save exp)
                  (save env)
                  (save continue)
                  (assign continue (label ev-if-decide))
                  (assign exp (op if-predicate) (reg exp))
                  (goto (label eval-dispatch))

                  ev-if-decide
                  (restore continue)
                  (restore env)
                  (restore exp)
                  (test (op true?) (reg val))
                  (branch (label ev-if-consequent))
    
                  ev-if-alternative
                  (assign exp (op if-alternative) (reg exp))
                  (goto (label eval-dispatch))
    
                  ev-if-consequent
                  (assign exp (op if-consequent) (reg exp))
                  (goto (label eval-dispatch))

                  ev-assignment
                  (assign unev (op assignment-variable) (reg exp))
                  (save unev)
                  (assign exp (op assignment-value) (reg exp))
                  (save env)
                  (save continue)
                  (assign continue (label ev-assignment-1))
                  (goto (label eval-dispatch))
    
                  ev-assignment-1
                  (restore continue)
                  (restore env)
                  (restore unev)
                  (perform (op set-variable-value!) (reg unev) (reg val) (reg env))
                  (assign val (const ok))
                  (goto (reg continue))

                  ev-definition
                  (assign unev (op definition-variable) (reg exp))
                  (save unev)
                  (assign exp (op definition-value) (reg exp))
                  (save env)
                  (save continue)
                  (assign continue (label ev-definition-1))
                  (goto (label eval-dispatch))
                  
                  ev-definition-1
                  (restore continue)
                  (restore env)
                  (restore unev)
                  (perform (op define-variable!) (reg unev) (reg val) (reg env))
                  (assign val (const ok))
                  (goto (reg continue)))))


(start eceval)