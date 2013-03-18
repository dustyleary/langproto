#!/usr/bin/env ruby

require './driver'

test_compile [42,"hi 0\nhi 1\nhi 2\n"], <<eot
    (define (blah ((n i32)) i32)
      (var i i32)
      (set! i 0)
      (while (i32:ult (get i) n)
        (printf "hi %d\n" (get i))
        (set! i (i32:add 1 (get i)))
      )
      0
    )
    (define (main () i32)
      (blah 3)
      42
    )
eot

