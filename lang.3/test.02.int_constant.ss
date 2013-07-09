#!/usr/bin/env csi -s

(include "compiler.ss")

(assert (equal? '(42 "") (exec-module
  '(defun main (main () i32) 42)
)))

