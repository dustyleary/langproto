#!/usr/bin/env ruby

require 'driver'

test_compile [24,"1 Hello World 0000002a!\n"], [
    [:define, [:foo, [], :i32], [:'i32:mul', 7, 6]],
    [:define, [:main, [], :i32], [:printf, "1 Hello World %08x!\n", [:foo]]]
]

test_compile [15,"2 Hello World!\n"], [
    [:define, [:foo, [], 'i8*'], [:strcat, "Wo\0\0\0", "rld"]],
    [:define, [:main, [], :i32], [:printf, "2 Hello %s!\n", [:foo]]]
]

