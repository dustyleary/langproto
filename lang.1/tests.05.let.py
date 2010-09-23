from driver import testCase

testCase('100', """
(define (smain)
    (let ((a 42) (b 43) (c 99))
        (- (+ c b) a)
    )
)
""")

testCase('97', """
(define (smain)
    (let ((a (+ 42 1)) (b (* 43 3)) (c (/ 99 9)))
        (- (+ c b) a)
    )
)
""")

