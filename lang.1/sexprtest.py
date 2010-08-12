import sexpr
from sexpr import sym
import unittest

class AtomTest(unittest.TestCase):
    def test_symbol(self):
        self.assertEqual(sym('asdf'), sexpr.parse1("asdf"))

    def test_int(self):
        self.assertEqual(123, sexpr.parse1("123"))

    def test_string(self):
        self.assertEqual('123', sexpr.parse1("'123'"))
        self.assertEqual('123', sexpr.parse1('"123"'))

    def test_string_with_backslash(self):
        self.assertEqual(r'12\3', sexpr.parse1(r"'12\\3'"))
        self.assertEqual('12\n3', sexpr.parse1(r"'12\n3'"))

class ListTest(unittest.TestCase):
    def test_empty_list(self):
        self.assertEqual([], sexpr.parse1("()"))

    def test_2_elements(self):
        self.assertEqual([123, 456], sexpr.parse1("(123 456)"))

    def test_nested_list(self):
        self.assertEqual([[[]]], sexpr.parse1("((()))"))

    def test_nested_with_elements(self):
        self.assertEqual([sym('a'), ['b', [3], 'b'], sym('a')], sexpr.parse1("(a ('b' (3) \"b\") a)"))

    def test_big_expr(self):
        self.assertEqual(['asdf', [sym('bar'), sym('baz')], [123], [[['what', 123]]], 'foo'], sexpr.parse1("('asdf' (bar baz) (123) ((('what' 123))) 'foo')"))

class MultiTest(unittest.TestCase):
    def test_2_empty_lists(self):
        self.assertEqual([[],[]], sexpr.parse("()()"))

    def test_2_integers(self):
        self.assertEqual([32,33], sexpr.parse("32 33"))

if __name__ == '__main__':
    unittest.main()

