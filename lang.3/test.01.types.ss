#!/usr/bin/env csi -s

(include "types.ss")

(assert (is-type? s8))
(assert (is-type? u8))

(assert (is-type? s64))
(assert (is-type? u64))
(assert (not (is-type? 'u64)))

(assert (is-type? f32))
(assert (is-type? f64))

(assert (is-type? void))

(assert (equal? "s8" (type->string s8)))
(assert (equal? "f64" (type->string f64)))

(assert (equal? "void" (type->string void)))

(assert (equal? "*s8" (type->string (make-pointer-type s8))))
(assert (equal? "**s8" (type->string (make-pointer-type (make-pointer-type s8)))))

(assert (equal? "(s8,s8->s8)" (type->string (make-function-type s8 (list s8 s8)))))
