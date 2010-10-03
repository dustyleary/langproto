import sexpr

from contextlib import contextmanager

class Type(object):
    def __init__(self, name):
        self.name = name
    def __repr__(self):
        return "<Type %r>" % self.name

class IntType(Type):
    def __init__(self, signed, width):
        self.signed = signed
        self.width = width
        name = ('s' if signed else 'u') + str(width)
        Type.__init__(self, name)

builtins = dict(
    void = Type('void'),
     u8 = IntType(False, 8),
    u16 = IntType(False, 16),
    u32 = IntType(False, 32),
    u64 = IntType(False, 64),
     s8 = IntType(True, 8),
    s16 = IntType(True, 16),
    s32 = IntType(True, 32),
    s64 = IntType(True, 64),
)
globals().update(builtins)

class CompileContext(object):
    def __init__(self):
        self.text = ""
        self.uniqIds = set()
        self.scopeChain = [builtins]

    def emit(self, s):
        self.text += s

    def emitln(self, s):
        self.emit(s+"\n")

    def getUniqId(self):
        for i in xrange(1000):
            id = "%x" + "%d" % i
            if id not in self.uniqIds:
                self.uniqIds.add(id)
                return id

    def resolveSymbol(self, sym):
        for scope in self.scopeChain:
            try:
                return scope[sym.txt]
            except KeyError:
                pass
        raise KeyError("identifier not found", sym)

    @contextmanager
    def pushScope(self, scope):
        try:
            self.scopeChain.insert(0, scope)
            yield
        finally:
            self.scopeChain.pop(0)

class LlvmBinOp(object):
    def __init__(self, name, asm):
        self.name = name
        self.asm = asm

    def compileApplication(self, cc, args):
        assert 2 == len(args)
        argids = [a.funcdefCompile(cc) for a in args]
        id = cc.getUniqId()
        cc.emitln("  %s = %s %s, %s" % (id, self.asm, argids[0], argids[1]))
        return id

opinfo = {
    '+': 'add',
    '-': 'sub',
    '*': 'mul',
    '/': 'sdiv',
    '%' : 'srem',
    '|' : 'or',
    '&' : 'and',
    '^' : 'xor',
    '>>': 'ashr',
    '<<': 'shl',
}

for oname in opinfo:
    oasm = opinfo[oname]
    op32 = LlvmBinOp(oname, oasm + " i32")
    builtins[oname] = op32

class ParseException(Exception): pass

class Expr(object):
    @staticmethod
    def __parse(s):
        types = [
            Let,
            Literal,
            VariableReference,
            FunctionApplication,
        ]
        for t in types:
            try:
                if t.parse == Expr.parse:
                    raise Exception("define parse for subtype %r" % t)
                return t.parse(s)
            except ParseException:
                pass
        else:
            raise ParseException("can't parse form into Expr", s)

    @staticmethod
    def parse(s):
        result = Expr.__parse(s)
        assert isinstance(result, Expr)
        return result

class Literal(Expr):
    def __init__(self, value):
        self.value = value

    def funcdefCompile(self, cc):
        return str(self.value)
    def moduleCompile(self, cc):
        return str(self.value)

    @staticmethod
    def parse(s):
        if not isinstance(s, (int, str)):
            raise ParseException
        return Literal(s)

class FunctionApplication(Expr):
    def __init__(self, func, args):
        assert isinstance(func, VariableReference)
        self.func = func
        self.args = args

    def funcdefCompile(self, cc):
        f = cc.resolveSymbol(self.func.name)
        return f.compileApplication(cc, self.args)

    @staticmethod
    def parse(s):
        if not isinstance(s, list):
            raise ParseException
        func = Expr.parse(s[0])
        args = [Expr.parse(a) for a in s[1:]]
        return FunctionApplication(func, args)

class VariableReference(Expr):
    def __init__(self, name):
        self.name = name

    def funcdefCompile(self, cc):
        target = cc.resolveSymbol(self.name)
        return target.funcdefCompile(cc)

    @staticmethod
    def parse(s):
        if not isinstance(s, sexpr.sym):
            raise ParseException
        return VariableReference(s)

class LetBinding(object):
    def __init__(self, name, expr):
        self.name = name
        self.expr = expr

    def funcdefCompile(self, cc):
        return self.expr.funcdefCompile(cc)

class Let(Expr):
    def __init__(self, bindings, body):
        self.bindings = bindings
        self.body = body

    def funcdefCompile(self, cc):
        for binding in self.bindings:
            binding.vc = binding.expr.funcdefCompile(cc)
        with cc.pushScope(self):
            return self.body.funcdefCompile(cc)

    def __getitem__(self, k):
        for b in self.bindings:
            if b.name == k:
                return b
        else:
            raise KeyError(k)

    @staticmethod
    def parse(s):
        if not isinstance(s, list):
            raise ParseException
        if s[0] != sexpr.sym('let'):
            raise ParseException

        if not isinstance(s[1], list):
            raise ParseException, "expected list of let bindings"

        bindings = []
        for binding in s[1]:
            if not isinstance(binding, list) or 2!=len(binding):
                raise ParseException, "not a valid let binding: %r" % binding
            if not isinstance(binding[0], sexpr.sym):
                raise ParseException, "not a valid let binding: %r" % binding
            name = binding[0].txt
            expr = Expr.parse(binding[1])
            bindings.append(LetBinding(name, expr))

        body = Expr.parse(s[2])
        return Let(bindings, body)

class TopLevelItem(object):
    @staticmethod
    def __parse(s):
        types = [
            FunctionDefinition,
            GlobalValue,
        ]
        for t in types:
            try:
                if t.parse == TopLevelItem.parse:
                    raise Exception("define parse for subtype %r" % t)
                return t.parse(s)
            except ParseException:
                pass
        else:
            raise ParseException("can't parse form into TopLevelItem", s)

    @staticmethod
    def parse(s):
        result = TopLevelItem.__parse(s)
        assert isinstance(result, TopLevelItem)
        return result

class GlobalValue(TopLevelItem):
    def __init__(self, name, expr):
        self.name = name
        self.expr = expr

    def moduleCompile(self, cc):
        ev = self.expr.moduleCompile(cc)
        cc.emitln("@%s = global i32 %s" % (self.name, ev))
        return cc.text

    def funcdefCompile(self, cc):
        id = cc.getUniqId()
        cc.emitln("%s = load i32* @%s" % (id, self.name))
        return id

    @staticmethod
    def parse(s):
        if not isinstance(s, list):
            raise ParseException
        if s[0] != sexpr.sym('define'):
            raise ParseException

        if not isinstance(s[1], sexpr.sym):
            raise ParseException

        name = s[1].txt
        expr = Expr.parse(s[2])
        return GlobalValue(name, expr)

class FunctionDefinition(TopLevelItem):
    class FuncArgRef(object):
        def __init__(self, name):
            self.name = name

        def funcdefCompile(self, cc):
            return "%" + self.name

    def __init__(self, name, args, body):
        self.name = name
        self.args = args
        self.body = body

    def compileApplication(self, cc, args):
        argids = [a.funcdefCompile(cc) for a in args]
        argtxt = ",".join(["i32 %s" % id for id in argids])
        id = cc.getUniqId()
        cc.emitln("  %s = tail call i32 @%s(%s) nounwind" % (id, self.name, argtxt))
        return id

    def moduleCompile(self, cc):
        with cc.pushScope(self):
            argspecs = ",".join(["i32 %"+a for a in self.args])
            cc.emitln("define i32 @%s(%s) nounwind readnone {" % (self.name, argspecs))
            cc.emitln("entry:")
            cc.emitln("  ret i32 "+self.body.funcdefCompile(cc))
            cc.emitln("}")

    def __getitem__(self, k):
        for a in self.args:
            if a==k:
                return self.FuncArgRef(a)
        else:
            raise KeyError(k)

    @staticmethod
    def parse(s):
        if not isinstance(s, list):
            raise ParseException
        if s[0] != sexpr.sym('define'):
            raise ParseException

        if not isinstance(s[1], list):
            raise ParseException
        if not isinstance(s[1][0], sexpr.sym):
            raise ParseException

        name = s[1][0].txt

        args = []
        for a in s[1][1:]:
            if not isinstance(a, sexpr.sym):
                raise ParseException
            args.append(a.txt)

        body = Expr.parse(s[2])
        return FunctionDefinition(name, args, body)

class Module(object):
    def __init__(self):
        self.funcs = {}

    def parse(self, sexprs):
        for s in sexprs:
            fd = TopLevelItem.parse(s)
            self.funcs[fd.name] = fd

    def compile(self):
        cc = CompileContext()
        with cc.pushScope(self):
            for fd in self.funcs.values():
                fd.moduleCompile(cc)
        return cc.text

    def __getitem__(self, k):
        return self.funcs[k]

def compile(sexprs):
    m = Module()
    m.parse(sexprs)
    return m.compile()

