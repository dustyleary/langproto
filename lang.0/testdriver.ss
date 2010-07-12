(require scheme/system)
(require mzlib/defmacro)

(load "compile.ss")

(define (compile-text t . ts)
  (call-with-output-string
    (lambda (p)
      (parameterize
        ([current-output-port p])
        (apply compile-program (cons t ts))))))

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

(define (run-program t . ts)
  (define asm (string-append (llvm-target-info) (apply compile-text (cons t ts))))
  (define f (open-output-file "out.ll" #:exists 'replace))
  (display asm f)
  (close-output-port f)
  (let* [
      (cmdline "llvmc driver.c out.ll -o out")
    ]
    (myexec cmdline)
    (if (equal? 'windows (system-type 'os))
      (myexec "out")
      (myexec "./out")
    )
  )
)

(define-macro (test-case expect-output t . ts)
  `(let [
      (output (apply run-program '(,t . ,ts)))
    ]
    (if
      (not (string=? output ,expect-output))
      (begin
        (display "FAIL") (newline)
        (display "expected: ") (display ,expect-output) (newline)
        (display "received: ") (display output) (newline)
        (display "program: ") (write '(,t ,ts)) (newline)
        (exit 1)
      )
      (begin
        (display "PASS") (newline)
      )
    )
  )
)
