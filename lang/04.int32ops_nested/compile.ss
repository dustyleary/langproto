(define (emit v . vv) (display v) (map display vv))

(define primopasms '[
  (+ . "add nsw i32")
  (- . "sub i32")
  (* . "mul i32")
  (/ . "sdiv i32")
  (% . "srem i32")
  ;(| . "or")
  (& . "and i32")
  (^ . "xor i32")
  (>> . "ashr i32")
  (<< . "shl i32")
])

(define (compile-program x)
  (define uniqid 0)
  (define (get-uniqid) (let ((v uniqid)) (set! uniqid (+ 1 uniqid)) (string-append "%x" (number->string v))))

  (define (compile-expr-primop x)
    (let* [
      (op (list-ref x 0))
      (opasm (cdr (assoc op primopasms)))
      (a (list-ref x 1))
      (b (list-ref x 2))
      (ac (compile-expr a))
      (bc (compile-expr b))
      (id (get-uniqid))
      ]
      (begin
        (emit "  " id " = " opasm " " ac ", " bc) (newline)
        id
      )
    )
  )

  (define (compile-expr-apply x)
    (compile-expr-primop x)
  )

  (define (compile-expr x)
    (cond
      ((list? x) (compile-expr-apply x))
      (else x)
    )
  )

  (emit "define i32 @scheme_entry() {") (newline)
  (emit "entry:") (newline)
  (emit "  ret i32 " (compile-expr x)) (newline)
  (emit "}") (newline)
)

