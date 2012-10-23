#!/usr/bin/env ruby

require 'sexpr'
require 'test/unit'

class TestSexpr < Test::Unit::TestCase

  def test_int_literal
    assert_equal 1234, Sexpr.read1("1234")
  end

  def test_string_literal
    assert_equal 'asdf', Sexpr.read1('"asdf"')
    assert_equal "asd\nf", Sexpr.read1('"asd\nf"')
    assert_equal "asd\n\\f\r", Sexpr.read1('"asd\n\\\\f\r"')
  end

  def test_empty_list
    assert_equal [], Sexpr.read1("()")
  end

  def test_list_with_one_int
    assert_equal [42], Sexpr.read1("(42)")
  end

  def test_weird_nested_int_list
    assert_equal [[[3], 4, [5, 6]]], Sexpr.read1("(((3) 4 (5 6)))")
  end

  def test_symbol
    assert_equal :asdf, Sexpr.read1('asdf')
    assert_equal [:asdf, "foo"], Sexpr.read1('(asdf "foo")')
  end

  def test_parse_multiple
    assert_equal [:asdf, "foo"], Sexpr.read('asdf "foo"')
  end

  def test_program
    expect = [
      [:define, [:foo, [], :i32], [:'i32:mul', 7, 6]],
      [:define, [:main, [], :i32], [:printf, "1 Hello World %08x!\n", [:foo]]]
    ]
    text = %q[
      (define (foo () i32) (i32:mul 7 6))
      (define (main () i32) (printf "1 Hello World %08x!\n" (foo)))
    ]
    assert_equal expect, Sexpr.read(text)
  end
end

