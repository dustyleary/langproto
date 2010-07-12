; ModuleID = 'example.c'
target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:32:32"
target triple = "i386-mingw32"

define i32 @add(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = add nsw i32 %b, %a                         ; <i32> [#uses=1]
  ret i32 %0
}

define i32 @sub(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = sub i32 %a, %b                             ; <i32> [#uses=1]
  ret i32 %0
}

define i32 @mul(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = mul i32 %b, %a                             ; <i32> [#uses=1]
  ret i32 %0
}

define i32 @div(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = sdiv i32 %a, %b                            ; <i32> [#uses=1]
  ret i32 %0
}

define i32 @mod(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = srem i32 %a, %b                            ; <i32> [#uses=1]
  ret i32 %0
}

define i32 @bitor(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = or i32 %b, %a                              ; <i32> [#uses=1]
  ret i32 %0
}

define i32 @bitand(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = and i32 %b, %a                             ; <i32> [#uses=1]
  ret i32 %0
}

define i32 @bitxor(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = xor i32 %b, %a                             ; <i32> [#uses=1]
  ret i32 %0
}

define i32 @shl(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = shl i32 %a, %b                             ; <i32> [#uses=1]
  ret i32 %0
}

define i32 @shr(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = ashr i32 %a, %b                            ; <i32> [#uses=1]
  ret i32 %0
}

define zeroext i8 @uchar(i32 %a) nounwind readnone {
entry:
  %0 = trunc i32 %a to i8                         ; <i8> [#uses=1]
  %retval12 = mul i8 %0, 15                       ; <i8> [#uses=1]
  ret i8 %retval12
}

define signext i8 @schar(i32 %a) nounwind readnone {
entry:
  %0 = trunc i32 %a to i8                         ; <i8> [#uses=1]
  %1 = mul i8 %0, 15                              ; <i8> [#uses=1]
  ret i8 %1
}

define i32 @scheme_entry(i32 %a, i32 %b) nounwind readnone {
entry:
  %0 = add nsw i32 %b, %a                         ; <i32> [#uses=1]
  %1 = mul i32 %0, %b                             ; <i32> [#uses=1]
  %2 = sub i32 %1, %a                             ; <i32> [#uses=1]
  ret i32 %2
}
