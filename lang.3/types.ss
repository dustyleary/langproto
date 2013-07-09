(use matchable)
(use srfi-13)

(define (make-int-type signed bits) (list int-type: signed bits))
(define (make-float-type bits) (list float-type: bits))

(define void void:)

(define s8 (make-int-type #t 8))
(define u8 (make-int-type #f 8))
(define s64 (make-int-type #t 64))
(define u64 (make-int-type #f 64))
(define f32 (make-float-type 32))
(define f64 (make-float-type 64))

(define (is-type? v)
  (match v
         [(`int-type: . _) #t]
         [(`float-type: . _) #t]
         [(`pointer-type: . _) #t]
         [(`function-type: . _) #t]
         [`void: #t] [_ #f]
         ))

(define (type->string v)
  (assert (is-type? v))
  (match v
         [(`int-type: signed bits) (string-append (if signed "s" "u") (number->string bits)) ]
         [(`float-type: bits) (string-append "f" (number->string bits)) ]
         [(`pointer-type: elementType) (string-append "*" (type->string elementType)) ]
         [(`function-type: retType argTypes) (string-append "(" (string-join (map type->string argTypes) ",") "->" (type->string retType) ")") ]
         [`void: "void" ]
         ))

(define (type->bits v)
  (assert (is-type? v))
  (match v
         [(int-type: signed bits) bits]
         [(float-type: bits) bits]
         ))

(define (make-pointer-type elementType)
  (assert (is-type? elementType))
  (list pointer-type: elementType))

(define (make-function-type retType argTypes)
  (assert (is-type? retType))
  (map (lambda (v) (assert (is-type? v))) argTypes)
  (list function-type: retType argTypes))

