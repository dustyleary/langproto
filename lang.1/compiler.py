import sexpr

class FunctionDefinition(object):
    def __init__(self, name, args, body):
        self.name = name
        self.args = args
        self.body = body

class FunctionApplication(object):
    def __init__(self, func, args):
        self.func = func
        self.args = args

class VariableReference(object):
    def __init__(self, name):
        self.name = name

class Literal(object):
    def __init__(self, value):
        self.value = value

class PrimOp(object):
    primOpAsms = {
        '+' : 'add nsw i32',
        '-' : 'sub i32',
        '*' : 'mul i32',
        '/' : 'sdiv i32',
        '%' : 'srem i32',
        '|' : 'or i32',
        '&' : 'and i32',
        '^' : 'xor i32',
        '>>': 'ashr i32',
        '<<': 'shl i32',
    }
    def __init__(self, op):
        self.op = op

class LetBinding(object):
    def __init__(self, name, expr):
        self.name = name
        self.expr = expr

class Let(object):
    def __init__(self, bindings, body):
        self.bindings = bindings
        self.body = body

def parseFuncDef(s):
    assert isinstance(s, list)
    assert s[0] == sexpr.sym('define')

    assert isinstance(s[1], list)
    assert isinstance(s[1][0], sexpr.sym)
    name = s[1][0].txt
    args = s[1][1:]

    body = parseExpr(s[2])
    return FunctionDefinition(name, args, body)

def parseLet(s):
    assert isinstance(s, list)
    assert s[0] == sexpr.sym('let')

    bindings = []
    assert isinstance(s[1], list)
    for binding in s[1]:
        if not isinstance(binding, list) or 2!=len(binding):
            raise AssertionError, "not a valid let binding: %r" % binding
        if not isinstance(binding[0], sexpr.sym):
            raise AssertionError, "not a valid let binding: %r" % binding
        name = binding[0].txt
        expr = parseExpr(binding[1])
        bindings.append(LetBinding(name, expr))

    body = parseExpr(s[2])
    return Let(bindings, body)

def parseFuncApply(s):
    assert isinstance(s, list)
    return FunctionApplication(parseExpr(s[0]), [parseExpr(a) for a in s[1:]])

def parseExpr(s):
    if isinstance(s, list):
        if False: pass
        elif s[0] == sexpr.sym('let'):
            return parseLet(s)
        else:
            return parseFuncApply(s)
    elif isinstance(s, (int, str)):
        return Literal(s)
    elif isinstance(s, sexpr.sym):
        return VariableReference(s)
    else:
        raise Exception("don't understand expr", s)

def parseItem(s):
    if isinstance(s, list):
        if False: pass
        elif s[0] == sexpr.sym('define'):
            return parseFuncDef(s)
    return parseExpr(s)

def compileFuncDef(fd):
    result = [""]
    def emit(s):
        result[0] += s
    def emitln(s):
        emit(s+"\n")

    localIndex = [-1]
    def getUniqId():
        localIndex[0] += 1
        return "%x" + "%d" % localIndex[0]

    def compileLiteral(l):
        return str(l.value)
    def compilePrimOp(fa, scopeChain):
        assert isinstance(fa.func, VariableReference)
        asm = PrimOp.primOpAsms[fa.func.name.txt]
        assert 2 == len(fa.args)
        a,b = fa.args
        ac = compileExpr(a, scopeChain)
        bc = compileExpr(b, scopeChain)
        id = getUniqId()
        emitln("  %s = %s %s, %s" % (id, asm, ac, bc))
        return id
    def compileFunctionApplication(fa, scopeChain):
        assert isinstance(fa.func, VariableReference)
        if fa.func.name.txt in PrimOp.primOpAsms:
            return compilePrimOp(fa, scopeChain)
        argids = [compileExpr(a, scopeChain) for a in fa.args]
        argtxt = ",".join(["i32 %s" % id for id in argids])
        id = getUniqId()
        emitln("  %s = tail call i32 @%s(%s) nounwind" % (id, fa.func.name.txt, argtxt))
        return id
    def compileVariableReference(vr, scopeChain):
        for scope in scopeChain:
            if False: pass
            elif isinstance(scope, FunctionDefinition):
                for a in scope.args:
                    if a.txt == vr.name.txt:
                        return "%" + vr.name.txt
            elif isinstance(scope, Let):
                for b in scope.bindings:
                    if b.name == vr.name.txt:
                        return b.vc
            else:
                raise Exception("don't understand scope", scope)
    def compileLet(l, scopeChain):
        for binding in l.bindings:
            binding.vc = compileExpr(binding.expr, scopeChain)
        return compileExpr(l.body, [l]+scopeChain)
    def compileExpr(expr, scopeChain):
        if isinstance(expr, Literal):
            return compileLiteral(expr)
        elif isinstance(expr, FunctionApplication):
            return compileFunctionApplication(expr, scopeChain)
        elif isinstance(expr, VariableReference):
            return compileVariableReference(expr, scopeChain)
        elif isinstance(expr, Let):
            return compileLet(expr, scopeChain)
        else:
            raise Exception("don't understand expr", expr)

    argspecs = ",".join(["i32 %"+a.txt for a in fd.args])
    emitln("define i32 @%s(%s) nounwind readnone {" % (fd.name, argspecs))
    emitln("entry:")
    emitln("  ret i32 "+compileExpr(fd.body, [fd]))
    emitln("}")

    return result[0]

def compile(sexprs):
    result = ''
    for s in sexprs:
        fd = parseFuncDef(s)
        result += compileFuncDef(fd)
    return result

