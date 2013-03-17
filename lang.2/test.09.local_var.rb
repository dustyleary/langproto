#!/usr/bin/env ruby

require 'driver'

test_compile [24,"1 Hello World 0000002a!\n"], <<eot
    (define (foo ((a i32) (b i32)) i32)
      (var c i32)
      (set! c (i32:mul a b))
      (get c)
    )
    (define (main () i32)
      (var result i32)
      (set! result (foo 2 7))
      (set! result (foo 3 (get result)))
      (printf "1 Hello World %08x!\n" (get result))
    )
eot

