#lang sicp
; (son Adam Cain)
; (son Cain Enoch)
; (son Enoch Irad)
; (son Irad Mehujael)
; (son Mehujael Methushael)
; (son Methushael Lamech)
; (wife Lamech Ada)
; (son Ada Jabal)
; (son Ada Jubal)

; (rule (grandson ?x ?y)
;       (and (son ?x ?u)
;            (son ?u ?y)))

; (rule (son ?x ?y)
;       (and (wife ?x ?u)
;            (son ?u ?y)))