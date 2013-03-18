#!/usr/bin/env ruby

require './driver'

test_compile [24,"1 Hello World 0000002a!\n"], <<eot
    (define (foo ((a i32) (b i32)) i32) (i32:mul a b))
    (define (main () i32) (printf "1 Hello World %08x!\n" (foo 6 7)))
eot

test_compile [16,"2 Hello Catdog!\n"], <<eot
    (define (foo ((a i8*)) i8*) (strcat a "dog"))
    (define (main () i32) (printf "2 Hello %s!\n" (foo "Cat\0\0\0\0")))
eot

