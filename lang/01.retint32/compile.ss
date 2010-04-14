(define (emit v . vv) (display v) (map display vv) (newline))

(define (compile-program x . xs)
  (emit "define i32 @scheme_entry() {")
  (emit "entry:")
  (emit "  ret i32 " x)
  (emit "}")
)

