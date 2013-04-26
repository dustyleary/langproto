#!/usr/bin/env csi -s

(include "compiler.ss")

(assert (equal? '(0 "hello world") (exec-llvm-prog
  '("@.str = private unnamed_addr constant [12 x i8] c\"hello world\\00\""
    "declare i32 @printf(i8* nocapture) nounwind"
    "define i32 @main() {"
    ("%cast210 = getelementptr [12 x i8]* @.str, i64 0, i64 0"
      "call i32 @printf(i8* %cast210)"
      "ret i32 0"
     )
    "}"
   )
)))

