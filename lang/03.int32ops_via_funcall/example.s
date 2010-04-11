; ModuleID = 'example.c'
target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:32:32"
target triple = "i386-mingw32"

define i32 @scheme_entry(i32 %a, i32 %b) nounwind {
entry:
  %0 = tail call i32 @add(i32 %a, i32 %b) nounwind ; <i32> [#uses=1]
  %1 = tail call i32 @mul(i32 %0, i32 %b) nounwind ; <i32> [#uses=1]
  %2 = tail call i32 @sub(i32 %1, i32 %a) nounwind ; <i32> [#uses=1]
  ret i32 %2
}

declare i32 @add(i32, i32)

declare i32 @mul(i32, i32)

declare i32 @sub(i32, i32)
