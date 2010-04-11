#lang scheme/load
(require scheme/system)

(define basedir (current-directory))

(define (run-tests-in-dir dir)
  (define abs-dir (path->complete-path dir basedir))
  (display (path->string dir)) (newline)
  (current-directory abs-dir)
  (let ((exitcode (system/exit-code "mzscheme tests.ss")))
    (if (not (= exitcode 0)) (exit exitcode) #f)
  )
)

(define testdirs (filter directory-exists? (directory-list)))

(map run-tests-in-dir testdirs)

