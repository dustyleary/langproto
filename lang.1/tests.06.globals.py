from driver import testCase

testCase('8', """
(define a 42)
(define b 50)

(define (smain)
    (- b a)
)
""")
