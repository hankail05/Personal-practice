#lang sicp
(define (factorial n)
  (if (= n 1)
      1
      (* (factorial (- n 1)) n)))

;; construct the procedure and skip over code for the procedure body
(assign val (op make-compiled-procedure) (label entry1) (reg env))
(goto (label after-lambda2))
entry1 ; calls to factorial will enter here
(assign env (op compiled-procedure-env) (reg proc))
(assign env (op extend-environment) (const (n)) (reg argl) (reg env))
;; begin actual procedure body
(save continue)
(save env)
;; compute (= n 1)
(assign proc (op lookup-variable-value) (const =) (reg env))
(assign val (const 1))
(assign argl (op list) (reg val))
(assign val (op lookup-variable-value) (const n) (reg env))
(assign argl (op cons) (reg val) (reg argl))
(test (op primitive-procedure?) (reg proc))
(branch (label primitive-branch6))
compiled-branch7
(assign continue (label after-call8))
(assign val (op compiled-procedure-entry) (reg proc))
(goto (reg val))
primitive-branch6
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
after-call8 ; val now contains result of (= n 1)
(restore env)
(restore continue)
(test (op false?) (reg val))
(branch (label false-branch4))
true-branch3 ; return 1
(assign val (const 1))
(goto (reg continue))
false-branch4
;; compute and return (* (factorial (- n 1)) n)
(assign proc (op lookup-variable-value) (const *) (reg env))
(save continue)
(save proc) ; save * procedure
(assign val (op lookup-variable-value) (const n) (reg env))
(assign argl (op list) (reg val))
(save argl) ; save partial argument list for *
;; compute (factorial (- n 1)), which is the other argument for *
(assign proc (op lookup-variable-value) (const factorial) (reg env))
(save proc) ; save factorial procedure
;; compute (- n 1), which is the argument for factorial
(assign proc (op lookup-variable-value) (const -) (reg env))
(assign val (const 1))
(assign argl (op list) (reg val))
(assign val (op lookup-variable-value) (const n) (reg env))
(assign argl (op cons) (reg val) (reg argl))
(test (op primitive-procedure?) (reg proc))
(branch (label primitive-branch9))
compiled-branch10
(assign continue (label after-call11))
(assign val (op compiled-procedure-entry) (reg proc))
(goto (reg val))
primitive-branch9
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
after-call11 ; val now contains result of (- n 1)
(assign argl (op list) (reg val))
(restore proc) ; restore factorial
;; apply factorial
(test (op primitive-procedure?) (reg proc))
(branch (label primitive-branch12))
compiled-branch13
(assign continue (label after-call14))
(assign val (op compiled-procedure-entry) (reg proc))
(goto (reg val))
primitive-branch12
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
after-call14 ; val now contains result of (factorial (- n 1))
(restore argl) ; restore partial argument list for *
(assign argl (op cons) (reg val) (reg argl))
(restore proc) ; restore *
(restore continue)
;; apply * and return its value
(test (op primitive-procedure?) (reg proc))
(branch (label primitive-branch15))
compiled-branch16
;; note that a compound procedure here is called tail-recursively
(assign val (op compiled-procedure-entry) (reg proc))
(goto (reg val))
primitive-branch15
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
(goto (reg continue))
after-call17
after-if5
after-lambda2
;; assign the procedure to the variable factorial
(perform (op define-variable!) (const factorial) (reg val) (reg env))
(assign val (const ok))


(define (factorial-alt n)
  (if (= n 1)
      1
      (* n (factorial-alt (- n 1)))))

;; construct the procedure and skip over code for the procedure body
(assign val (op make-compiled-procedure) (label entry1) (reg env))
(goto (label after-lambda2))
entry1 ; calls to factorial will enter here
(assign env (op compiled-procedure-env) (reg proc))
(assign env (op extend-environment) (const (n)) (reg argl) (reg env))
;; begin actual procedure body
(save continue)
(save env)
;; compute (= n 1)
(assign proc (op lookup-variable-value) (const =) (reg env))
(assign val (const 1))
(assign argl (op list) (reg val))
(assign val (op lookup-variable-value) (const n) (reg env))
(assign argl (op cons) (reg val) (reg argl))
(test (op primitive-procedure?) (reg proc))
(branch (label primitive-branch6))
compiled-branch7
(assign continue (label after-call8))
(assign val (op compiled-procedure-entry) (reg proc))
(goto (reg val))
primitive-branch6
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
after-call8 ; val now contains result of (= n 1)
(restore env)
(restore continue)
(test (op false?) (reg val))
(branch (label false-branch4))
true-branch3 ; return 1
(assign val (const 1))
(goto (reg continue))
false-branch4
;; compute and return (* n (factorial-alt (- n 1)))
(assign proc (op lookup-variable-value) (const *) (reg env))
(save continue)
(save proc) ; save * procedure
(save env)
;; compute (factorial-alt (- n 1)), which is the argument for *
(assign proc (op lookup-variable-value) (const factorial-alt) (reg env))
(save proc) ; save factorial-alt procedure
;; compute (- n 1), which is the argument for factorial-alt
(assign proc (op lookup-variable-value) (const -) (reg env))
(assign val (const 1))
(assign argl (op list) (reg val))
(assign val (op lookup-variable-value) (const n) (reg env))
(assign argl (op cons) (reg val) (reg argl))
(test (op primitive-procedure?) (reg proc))
(branch (label primitive-branch9))
compiled-branch10
(assign continue (label after-call11))
(assign val (op compiled-procedure-entry) (reg proc))
(goto (reg val))
primitive-branch9
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
after-call11 ; val now contains result of (- n 1)
(assign argl (op list) (reg val))
(restore proc) ; restore factorial
;; apply factorial
(test (op primitive-procedure?) (reg proc))
(branch (label primitive-branch12))
compiled-branch13
(assign continue (label after-call14))
(assign val (op compiled-procedure-entry) (reg proc))
(goto (reg val))
primitive-branch12
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
after-call14 ; val now contains result of (factorial (- n 1))
(assign argl (op list) (reg val))
(restore env)
(assign val (op lookup-variable-value) (const n) (reg env)) ; get n, which is the other argument for *
(assign argl (op cons) (reg val) (reg argl))
(restore proc) ; restore *
(restore continue)
;; apply * and return its value
(test (op primitive-procedure?) (reg proc))
(branch (label primitive-branch15))
compiled-branch16
(assign val (op compiled-procedure-entry) (reg proc))
(goto (reg val))
primitive-branch15
(assign val (op apply-primitive-procedure) (reg proc) (reg argl))
(goto (reg continue))
after-call17
after-if5
after-lambda2
;; assign the procedure to the variable factorial
(perform (op define-variable!) (const factorial-alt) (reg val) (reg env))
(assign val (const ok))


; Factorial-alt doesn't save argl to compute (* n (factorial (- n 1)), but it saves env, so there is no difference of stack space.