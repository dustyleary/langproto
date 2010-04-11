#lang scheme/load

(load "../testdriver.ss")

(test-case "42" 42)
(test-case "99" 99)
(test-case "-1294967296" -1294967296)
