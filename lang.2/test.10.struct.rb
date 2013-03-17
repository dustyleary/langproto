#!/usr/bin/env ruby

require 'driver'

test_compile [24,"1 Hello World 0000002a!\n"], <<eot
    (defstruct st_blah
      (int_field i32)
      (char_field i8)
    )
    (define (main () i32)
      (var foo st_blah)
      (set! (struct-field foo int_field) 42)
      (printf "1 Hello World %08x!\n" (get (struct-field foo int_field)))
    )
eot

test_compile [24,"1 Hello World 0000002a!\n"], <<eot
    (defstruct st_blah
      (field1 i32)
      (field2 i32)
    )
    (define (func_struct_return ((iparm i32) (cparm i32)) st_blah)
      (var result st_blah)
      (set! (struct-field result field1) (i32:mul iparm 3))
      (set! (struct-field result field2) (i32:mul cparm 7))
      (get result)
    )
    (define (main () i32)
      (var foo st_blah)
      (set! foo (func_struct_return 14 0))
      (printf "1 Hello World %08x!\n" (get (struct-field foo field1)))
    )
eot

