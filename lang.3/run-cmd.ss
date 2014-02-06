#lang racket

(provide run-cmd)

(define (run-cmd cmd)
  (let*-values
   ([(outpath) (make-temporary-file)]
    [(errpath) (make-temporary-file)]
    [(outport) (open-output-file outpath #:exists 'replace)]
    [(errport) (open-output-file errpath #:exists 'replace)]
    [(p stdout stdin stderr) (subprocess outport #f errport "/bin/bash" "-c" cmd)])

   (close-output-port stdin)
   (close-output-port outport)
   (close-output-port errport)

   (subprocess-wait p)

   (define status-code (subprocess-status p))
   (if (not (equal? status-code 0))
       (error 'run-cmd "subprocess failed with status code: ~a" status-code)
     null)

   (define (read-file path)
     (define file (open-input-file path))
     (define result (port->bytes file))
     (close-input-port file)
     result)

   (list status-code (read-file outpath) (read-file errpath))))

