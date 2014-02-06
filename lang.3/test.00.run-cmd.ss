#!/usr/bin/env racket
#lang racket

(require "unittest.ss"
         "run-cmd.ss")

(check-equal? (run-cmd "echo hi") '(0 #"hi\n" #""))

