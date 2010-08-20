from driver import testCase

testCase('620', """
(define (thefunc) (* (/ (- 50 10) 2) (+ 30 1)))
(define (smain) (thefunc))
""")

testCase('620', """
(define (thefunc a b) (* (/ (- a b) 2) (+ 30 1)))
(define (smain) (thefunc 50 10))
""")

