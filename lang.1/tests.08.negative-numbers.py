from driver import testCase

testCase('-4', """
(define (smain)
    (+ 8 -12)
)
""")

testCase('-10', """
(define (smain)
    (/ -50 5)
)
""")

testCase('-3', """
(define (smain)
    (% -53 5)
)
""")
