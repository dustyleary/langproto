from driver import testCase

testCase('25',  "(define (smain) (+ 20 5))")
testCase('15',  "(define (smain) (- 20 5))")
testCase('100', "(define (smain) (* 20 5))")
testCase('4',   "(define (smain) (/ 20 5))")
testCase('0',   "(define (smain) (% 20 5))")
testCase('21',  "(define (smain) (| 20 1))")
testCase('0',   "(define (smain) (& 20 1))")
testCase('21',  "(define (smain) (^ 20 1))")
testCase('16',  "(define (smain) (^ 20 4))")
testCase('10',  "(define (smain) (>> 20 1))")
testCase('40',  "(define (smain) (<< 20 1))")

