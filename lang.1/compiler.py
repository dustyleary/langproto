import sexpr

from contextlib import contextmanager

class Type(object):
    def __init__(self, name):
        self.name = name
    def __repr__(self):
        return "<%s %r>" % (type(self), self.name)

class IntType(Type):
    def __init__(self, signed, width):
        self.signed = signed
        self.width = width
        name = ('s' if signed else 'u') + str(width)
        Type.__init__(self, name)

    @property
    def llvmType(self):
        return 'i%d' % self.width

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
        self.indentLevel = 0

    @contextmanager
    def indent(self):
        try:
            self.indentLevel += 1
            yield
        finally:
            self.indentLevel -= 1

    def emitln(self, s):
        line = self.indentLevel*"  " + s + "\n"
        self.text += line

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

class NameAndTypeDecl(object):
    DEFAULT = object()
    def __init__(self, name, declaredType):
        self.name = name
        self.declaredType = declaredType

    def __repr__(self):
        dt = 'DEFAULT' if self.isDefault else repr(self.declaredType)
        return "<NameAndTypeDecl %r %s>" % (self.name, dt)

    @property
    def isDefault(self):
        return self.declaredType is self.DEFAULT

    @staticmethod
    def parse(s):
        if isinstance(s, sexpr.sym):
            return NameAndTypeDecl(s.txt, NameAndTypeDecl.DEFAULT)
        elif isinstance(s, list):
            if len(s) == 3:
                if s[0] == sexpr.sym(':'):
                    if isinstance(s[1], sexpr.sym):
                        return NameAndTypeDecl(s[1].txt, Expr.parse(s[2]))
        raise ParseException, s

class LlvmBinOp(object):
    def __init__(self, name, asm):
        self.name = name
        self.asm = asm

    def compileApplication(self, cc, args):
        assert 2 == len(args)
        argids = [a.funcdefCompile(cc) for a in args]
        id = cc.getUniqId()
        cc.emitln("%s = %s %s, %s" % (id, self.asm, argids[0], argids[1]))
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

widths = [8,16,32,64]
for opname in opinfo:
    opasm = opinfo[opname]
    for w in widths:
        fullopname_u = opname+'u'+str(w)
        fullopname_s = opname+'s'+str(w)
        op = LlvmBinOp(fullopname_u, opasm + " i"+str(w))
        builtins[fullopname_u] = op
        op = LlvmBinOp(fullopname_s, opasm + " i"+str(w))
        builtins[fullopname_s] = op
        if w == 32:
            builtins[opname] = op

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
    def __init__(self, nameAndType, expr):
        self.nameAndType = nameAndType
        self.expr = expr

    def funcdefCompile(self, cc):
        return self.expr.funcdefCompile(cc)

    @property
    def name(self):
        return self.nameAndType.name

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
            nameAndType = NameAndTypeDecl.parse(binding[0])
            expr = Expr.parse(binding[1])
            bindings.append(LetBinding(nameAndType, expr))

        body = Expr.parse(s[2])
        return Let(bindings, body)

class TopLevelItem(object):
    @staticmethod
    def __parse(s):
        types = [
            GlobalValue,
            FunctionDefinition,
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
    def __init__(self, nameAndType, expr):
        self.nameAndType = nameAndType
        self.expr = expr

    @property
    def name(self):
        return self.nameAndType.name

    @property
    def typeName(self):
        if self.nameAndType.isDefault:
            return sexpr.sym('s32')
        else:
            return self.nameAndType.declaredType.name

    @property
    def llvmType(self):
        cc = CompileContext()
        rt = cc.resolveSymbol(self.typeName)
        return rt.llvmType

    def moduleCompile(self, cc):
        ev = self.expr.moduleCompile(cc)
        cc.emitln("@%s = global %s %s" % (self.name, self.llvmType, ev))
        return cc.text

    def funcdefCompile(self, cc):
        id = cc.getUniqId()
        cc.emitln("%s = load %s* @%s" % (id, self.llvmType, self.name))
        return id

    @staticmethod
    def parse(s):
        if not isinstance(s, list):
            raise ParseException
        if s[0] != sexpr.sym('define'):
            raise ParseException

        nameAndType = NameAndTypeDecl.parse(s[1])
        expr = Expr.parse(s[2])
        return GlobalValue(nameAndType, expr)

class FunctionDefinition(TopLevelItem):
    class FuncArg(object):
        def __init__(self, nameAndType):
            self.nameAndType = nameAndType

        def funcdefCompile(self, cc):
            return "%" + self.name

        @property
        def name(self):
            return self.nameAndType.name

        @property
        def llvmType(self):
            cc = CompileContext()
            tn = sexpr.sym('s32') if self.nameAndType.isDefault else self.nameAndType.declaredType.name
            t = cc.resolveSymbol(tn)
            return t.llvmType

    def __init__(self, nameAndType, args, body):
        self.nameAndType = nameAndType
        self.args = args
        self.body = body

    @property
    def name(self):
        return self.nameAndType.name

    @property
    def returnTypeName(self):
        if self.nameAndType.isDefault:
            return sexpr.sym('s32')
        else:
            return self.nameAndType.declaredType.name

    @property
    def llvmReturnType(self):
        cc = CompileContext()
        rt = cc.resolveSymbol(self.returnTypeName)
        return rt.llvmType

    def compileApplication(self, cc, args):
        argids = [a.funcdefCompile(cc) for a in args]
        argtxt = ", ".join(["%s %s" % (a.llvmType, id) for a,id in zip(self.args, argids)])
        id = cc.getUniqId()
        cc.emitln("%s = call %s @%s(%s) nounwind" % (id, self.llvmReturnType, self.name, argtxt))
        return id

    def moduleCompile(self, cc):
        with cc.pushScope(self):
            def argspec(a):
                return "%s %%%s" % (a.llvmType, a.name)

            argspecs = ", ".join([argspec(a) for a in self.args])
            cc.emitln("define %s @%s(%s) nounwind readnone {" % (self.llvmReturnType, self.name, argspecs))
            cc.emitln("entry:")
            with cc.indent():
                cc.emitln("ret %s %s" % (self.llvmReturnType, self.body.funcdefCompile(cc)))
            cc.emitln("}")

    def __getitem__(self, k):
        for fa in self.args:
            if fa.name==k:
                return fa
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
        nameAndType = NameAndTypeDecl.parse(s[1][0])

        args = []
        for a in s[1][1:]:
            fa = FunctionDefinition.FuncArg(NameAndTypeDecl.parse(a))
            args.append(fa)

        body = Expr.parse(s[2])
        return FunctionDefinition(nameAndType, args, body)

class Module(object):
    def __init__(self):
        self.entries = {}

    def parse(self, sexprs):
        for s in sexprs:
            i = TopLevelItem.parse(s)
            self.entries[i.name] = i

    def compile(self):
        cc = CompileContext()
        with cc.pushScope(self):
            for fd in self.entries.values():
                fd.moduleCompile(cc)
        return cc.text

    def __getitem__(self, k):
        return self.entries[k]

def compile(sexprs):
    m = Module()
    m.parse(sexprs)
    return m.compile()

