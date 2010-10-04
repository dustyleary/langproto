from driver import testCase


testCase('4', """
(define ((: smain u8))
    (+u8 250 10)
)
""")

testCase('28', """
(define ((: smain u8))
    (let (
        ((: a u8) 250)
        ((: b u8) 10)
        ((: c u8) 7)
        )
        (*u8 (+u8 a b) c)
    )
)
""")

testCase('4', """
(define ((: foo u8) (: a u8) (: b u8))
    (+u8 a b)
)

(define ((: smain u8))
    (foo 250 10)
)
""")


testCase('14', """
(define (: a u16) 65500)
(define (: b u16) 50)

(define ((: smain u16))
    (+u16 a b)
)
""")
