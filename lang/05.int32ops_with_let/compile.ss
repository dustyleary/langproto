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

  (define scope-chain '())
  (define (push-scope-chain)
    (let [(new-scope (make-hash))]
      (set! scope-chain (cons new-scope scope-chain))
    )
  )
  (define (pop-scope-chain)
    (set! scope-chain (cdr scope-chain))
  )

  (define (resolve-name n)
    (define (resolve sc n)
      (if (equal? sc '()) (error (string-append "undefined variable: " n))
        (if (hash-has-key? (car sc) n) (hash-ref (car sc) n) (resolve (cdr sc) n))
      )
    )
    (resolve scope-chain n)
  )

  (define-struct varref (compiled_id))

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

  (define (compile-expr-let x)
    (define (add-binding binding)
      (let ([n (car binding)] [v (compile-expr (cadr binding))])
        (hash-set! (car scope-chain) n (make-varref v))
      )
    )

    (let [(bindings (cadr x)) (body (caddr x))]
      (begin
        (push-scope-chain)
        (map add-binding bindings)
        (let ((result (compile-expr body)))
          (begin
            (pop-scope-chain)
            result
          )
        )
      )
    )
  )

  (define (compile-expr-varref x)
    (let ([varref (resolve-name x)])
      (varref-compiled_id varref)
    )
  )

  (define (compile-expr-apply x)
    (cond
      [(equal? (car x) 'let) (compile-expr-let x)]
      [(member (car x) (map car primopasms)) (compile-expr-primop x)]
      [else (error (string-append "can't compile application. unhandled first element: " (format "~a" x)))]
    )
  )

  (define (compile-expr x)
    (cond
      ((list? x) (compile-expr-apply x))
      ((integer? x) x)
      ((symbol? x) (compile-expr-varref x))
      [else (error (string-append "can't compile expr: " (format "~a" x)))]
    )
  )

  (emit "define i32 @scheme_entry() {") (newline)
  (emit "entry:") (newline)
  (emit "  ret i32 " (compile-expr x)) (newline)
  (emit "}") (newline)
)

