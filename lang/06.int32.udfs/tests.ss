#lang scheme/load

(load "../testdriver.ss")

(test-case "99"
  (define (scheme_entry) 99)
)
(test-case "25"
  (define (scheme_entry) (+ 20 5))
)
(test-case "620"
  (define (scheme_entry) (* (/ (- 50 10) 2) (+ 30 1)))
)

(test-case "620"
  (define (scheme_entry)
    (let [
      (a (- 50 10))
      (b (/ a 2))
      (c (+ 30 1))
      ]
      (* b c)
    )
  )
)

(test-case "999"
  (define (thefunc) 999)
  (define (scheme_entry) (thefunc))
)

(test-case "620"
  (define (a) (- 50 10))
  (define (b v) (/ v 2))
  (define (c) (+ 30 1))
  (define (thefunc) (* (b (a)) (c)))
  (define (scheme_entry) (thefunc))
)
