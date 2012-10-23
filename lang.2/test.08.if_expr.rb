#!/usr/bin/env ruby

require 'driver'

test_compile [10,"Hello 7 5\n"], [
    [:define, [:foo, [[:a, 'i32']], 'i32'], [:if, [:'i32:ugt', :a, 5], :a, 5]],
    [:define, [:main, [], 'i32'], [:printf, "Hello %d %d\n", [:foo, 7], [:foo, 4]]]
]

