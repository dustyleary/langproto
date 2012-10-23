#!/usr/bin/env ruby

require 'driver'

test_compile_expr [13,"Hello World!\n"], %q[   (printf "Hello World!\n")   ]

