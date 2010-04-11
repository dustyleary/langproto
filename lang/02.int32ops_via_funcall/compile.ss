(define (emit v . vv) (display v) (map display vv) (newline))

(define opfuns
  (make-hash '[
    (+ . "add")
    (- . "sub")
    (* . "mul")
    (/ . "div")
    (% . "mod")
    ;(| . "or")
    (& . "bitand")
    (^ . "bitxor")
    (>> . "shr")
    (<< . "shl")
  ])
)

(define (compile-program x)
  (hash-map opfuns (lambda (k v) (emit "declare i32 @" v "(i32, i32) nounwind readonly"))) 
  (emit "define i32 @scheme_entry() {")
  (emit "entry:")
  (cond
    [(list? x)
     (let* (
        (op (list-ref x 0))
        (opfun (hash-ref opfuns op))
        (a (list-ref x 1))
        (b (list-ref x 2))
        )
        (emit "  %0 = tail call i32 @" opfun "(i32 " a ", i32 " b ")")
        (emit "  ret i32 %0")
     )]

    [else (emit "  ret i32 " x)]
  )
  (emit "}")
)

