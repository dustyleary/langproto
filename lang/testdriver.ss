(require scheme/system)
(require mzlib/defmacro)

(load "compile.ss")

(define (compile-text program)
  (call-with-output-string
    (lambda (p)
      (parameterize
        ([current-output-port p])
        (compile-program program)))))

(define (myexec cmdline)
  (define out (open-output-string))
  (define in (open-input-string ""))
  (define p (process/ports out in out cmdline))
  (define control (list-ref p 4))
  (control 'wait)
  (let* [
    (output (bytes->string/locale (get-output-bytes out)))

    (display-status (lambda ()
      (display "==================================") (newline)
      (display cmdline) (newline)
      (display output) (newline)
      (display "==================================") (newline)
      ))
    ]
    (if (not (= 0 (control `exit-code)))
      (begin
        (display-status)
        (raise "failure")
      )
      output
    )
  )
)

(define (llvm-target-info)
  (define f (open-output-file ".temp.c" #:exists 'replace))
  (close-output-port f)
  (myexec "llvm-gcc --emit-llvm -S .temp.c -o -")
)

(define (run-program program)
  (define asm (string-append (llvm-target-info) (compile-text program)))
  (define f (open-output-file "out.ll" #:exists 'replace))
  (display asm f)
  (close-output-port f)
  (let* [
      (cmdline "llvmc driver.c out.ll -o out")
    ]
    (myexec cmdline)
    (myexec "./out")
  )
)

(define-macro (test-case expect-output program)
  `(let [
      (output (run-program ',program))
    ]
    (if
      (not (string=? output ,expect-output))
      (begin
        (display "FAIL") (newline)
        (display "expected: ") (display ,expect-output) (newline)
        (display "received: ") (display output) (newline)
        (display "program: ") (write ',program) (newline)
        (exit 1)
      )
      (begin
        (display "PASS") (newline)
      )
    )
  )
)
