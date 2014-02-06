#lang racket

;makes check failures (exit 1)

(require rackunit)

(provide (all-from-out rackunit))

(define default-check-hander (current-check-handler))
(define (my-check-handler x)
  (default-check-hander x)
  (exit 1))

(current-check-handler my-check-handler)

