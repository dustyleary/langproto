#!/usr/bin/env ruby

require 'driver'

test_compile_expr [16,"Hello World 42!\n"], [:printf, "Hello %s %d!\n", "World", 42]

