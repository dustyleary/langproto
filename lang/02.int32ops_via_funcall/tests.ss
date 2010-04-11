#lang scheme/load

(load "../testdriver.ss")

(test-case "99" 99)
(test-case "25"  (+ 20 5))
(test-case "15"  (- 20 5))
(test-case "100" (* 20 5))
(test-case "4"   (/ 20 5))
(test-case "0"   (% 20 5))
;(test-case "21"  (| 20 1))
(test-case "0"   (& 20 1))
(test-case "21"  (^ 20 1))
(test-case "16"  (^ 20 4))
(test-case "10"  (>> 20 1))
(test-case "40"  (<< 20 1))
