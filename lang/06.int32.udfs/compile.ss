(define (emit v . vv) (map display (cons v vv)))

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

(define (compile-program def . defs)
  (define uniqid 0)
  (define (get-uniqid) (let ((v uniqid)) (set! uniqid (+ 1 uniqid)) (string-append "%x" (number->string v))))

  (define (make-scope) (make-hash))
  (define global-scope (make-scope))

  (define scope-chain '(global-scope))
  (define (push-scope-chain)
    (let [(new-scope (make-scope))]
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

  (define (compile-expr-funapply x)
    (let* [
      (n (car x))
      (args (cdr x))
      (compiled-args (map compile-expr args))
      (id (get-uniqid))
      ]
      (begin
        (emit "  " id " = tail call i32 @" n "(")
        (if (null? compiled-args) #f
          (let [
            (a0 (car compiled-args))
            (an (cdr compiled-args))
            ]
            (emit "i32 " a0)
            (map (lambda (a) (emit ", i32 " a)) an)
          )
        )
        (emit ") nounwind") (newline)
        id
      )
    )
  )

  (define (compile-expr-apply x)
    (cond
      [(equal? (car x) 'let) (compile-expr-let x)]
      [(member (car x) (map car primopasms)) (compile-expr-primop x)]
      ((symbol? (car x)) (compile-expr-funapply x))
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

  (define (compile-def d)
    (if (not (list? d)) (error (string-append "expected (define ...) got " (format "~a" d))) #f)
    (if (not (equal? (car d) 'define)) (error (string-append "expected (define ...) got " (format "~a" d))) #f)
    (let* [
      (nameargs (list-ref d 1))
      (body (list-ref d 2))
      (name (car nameargs))
      (args (cdr nameargs))
      ]
      (emit "define i32 @" name "(")
      (if (null? args) #f
        (let [
          (a0 (car args))
          (an (cdr args))
          ]
          (emit "i32 %" a0)
          (map (lambda (a) (emit ", i32 %" a)) an)
        )
      )
      (emit ") {") (newline)
      (emit "entry:") (newline)

      (push-scope-chain)
      (map (lambda (a) (hash-set! (car scope-chain) a (make-varref (string-append "%" (symbol->string a))))) args)
      (emit "  ret i32 " (compile-expr body)) (newline)
      (pop-scope-chain)

      (emit "}") (newline)
    )
  )
  (map compile-def (cons def defs))
)

