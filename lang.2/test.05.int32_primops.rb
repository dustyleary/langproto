#!/usr/bin/env ruby

require 'driver'

test_compile_expr [24,"1 Hello World 0000000d!\n"], [:printf, "1 Hello World %08x!\n", [:'i32:add', 6, 7]]
test_compile_expr [24,"2 Hello World ffffffff!\n"], [:printf, "2 Hello World %08x!\n", [:'i32:sub', 6, 7]]
test_compile_expr [24,"3 Hello World 0000002a!\n"], [:printf, "3 Hello World %08x!\n", [:'i32:mul', 6, 7]]
test_compile_expr [24,"4 Hello World 00000002!\n"], [:printf, "4 Hello World %08x!\n", [:'i32:sdiv', 17, 7]]
test_compile_expr [24,"5 Hello World 00000003!\n"], [:printf, "5 Hello World %08x!\n", [:'i32:srem', 17, 7]]
                                                                 
test_compile_expr [24,"6 Hello World 0000001c!\n"], [:printf, "6 Hello World %08x!\n", [:'i32:shl', 7, 2]]
                                                                 
test_compile_expr [24,"7 Hello World ffffffff!\n"], [:printf, "7 Hello World %08x!\n", [:'i32:ashr', -2, 1]]
test_compile_expr [24,"8 Hello World 7fffffff!\n"], [:printf, "8 Hello World %08x!\n", [:'i32:lshr', -2, 1]]

