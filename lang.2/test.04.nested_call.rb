#!/usr/bin/env ruby

require 'driver'

test_compile_expr [15,"Hello World 5!\n"], [:printf, "Hello %s %d!\n", "World", [:strlen, "World"]]

