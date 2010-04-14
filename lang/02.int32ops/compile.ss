(define (emit v . vv) (display v) (map display vv) (newline))

(define (compile-program x . xs)
  (emit "define i32 @scheme_entry() {")
  (emit "entry:")
  (cond
    [(list? x)
     (let* (
        (opasms
          (make-hash '[
            (+ . "add nsw")
            (- . "sub")
            (* . "mul")
            (/ . "sdiv")
            (% . "srem")
            ;(| . "or")
            (& . "and")
            (^ . "xor")
            (>> . "ashr")
            (<< . "shl")
            ]))
        (op (list-ref x 0))
        (opasm (hash-ref opasms op))
        (a (list-ref x 1))
        (b (list-ref x 2))
        )
        (emit "  %0 = " opasm " i32 " a ", " b)
        (emit "  ret i32 %0")
     )]

    [else (emit "  ret i32 " x)]
  )
  (emit "}")
)

