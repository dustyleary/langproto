#!/usr/bin/env ruby

sample_c_code = <<EOT

typedef struct {
  int int_field;
  char char_field;
  double double_field;
} st_blah;

st_blah func_struct_return(int iparm, char cparm) {
  st_blah result;
  result.int_field = iparm*3;
  result.char_field = cparm*7;
  return result;
}

double func_struct_parm(st_blah param) {
  return (param.int_field + param.char_field) * param.double_field;
}

EOT

require 'driver'

test_compile [24,"1 Hello World 0000002a!\n"], <<eot
    (defstruct st_blah
      (int_field i32)
      (char_field i8)
    )
    (define (main () i32)
      (var foo st_blah)
      (struct-set! foo int_field 42)
      (printf "1 Hello World %08x!\n" (struct-get foo int_field))
    )
eot

# test_compile [24,"1 Hello World 0000002a!\n"], <<eot
#     (defstruct st_blah
#       (int_field i32)
#       (char_field i8)
#       (double_field double)
#     )
#     (define (func_struct_return ((iparm i32) (cparm i8)) st_blah)
#       (var result st_blah)
#       (struct-set! result 'int_field (i32:mul iparm 3))
#       (struct-set! result 'char_field (i32:mul cparm 7))
#       result
#     )
#     (define (main () i32)
#       (printf "1 Hello World %08x!\n" (foo 6 7))
#     )
# eot
# 
