#lang scheme/load

(load "../testdriver.ss")

(test-case "99" 99)
(test-case "25" (+ 20 5))
(test-case "620" (* (/ (- 50 10) 2) (+ 30 1)))

(test-case "620"
  (let ([a (- 50 10)][b (/ a 2)] [c (+ 30 1)]) (* b c))
)
