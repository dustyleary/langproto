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

def parseFuncDef(s):
    assert isinstance(s, list)
    assert s[0] == sexpr.sym('define')

    assert isinstance(s[1], list)
    assert isinstance(s[1][0], sexpr.sym)
    name = s[1][0].txt
    args = s[1][1:]

    body = parseItem(s[2])
    return FunctionDefinition(name, args, body)

def parseFuncApply(s):
    assert isinstance(s, list)
    return FunctionApplication(parseItem(s[0]), [parseItem(a) for a in s[1:]])

def parseItem(s):
    if isinstance(s, list):
        if s[0] == sexpr.sym('define'):
            return parseFuncDef(s)
        else:
            return parseFuncApply(s)
    elif isinstance(s, (int, str)):
        return Literal(s)
    elif isinstance(s, sexpr.sym):
        return VariableReference(s)
    else:
        raise Exception("don't understand item", s)

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
    def compilePrimOp(fa):
        assert isinstance(fa.func, VariableReference)
        asm = PrimOp.primOpAsms[fa.func.name.txt]
        assert 2 == len(fa.args)
        a,b = fa.args
        ac = compileExpr(a)
        bc = compileExpr(b)
        id = getUniqId()
        emitln("  %s = %s %s, %s" % (id, asm, ac, bc))
        return id
    def compileFunctionApplication(fa):
        assert isinstance(fa.func, VariableReference)
        if fa.func.name.txt in PrimOp.primOpAsms:
            return compilePrimOp(fa)
        argids = [compileExpr(a) for a in fa.args]
        argtxt = ",".join(["i32 %s" % id for id in argids])
        id = getUniqId()
        emitln("  %s = tail call i32 @%s(%s) nounwind" % (id, fa.func.name.txt, argtxt))
        return id
    def compileVariableReference(vr):
        return "%" + vr.name.txt

    def compileExpr(expr):
        if isinstance(expr, Literal):
            return compileLiteral(expr)
        elif isinstance(expr, FunctionApplication):
            return compileFunctionApplication(expr)
        elif isinstance(expr, VariableReference):
            return compileVariableReference(expr)
        else:
            raise Exception("don't understand expr", expr)

    argspecs = ",".join(["i32 %"+a.txt for a in fd.args])
    emitln("define i32 @%s(%s) nounwind readnone {" % (fd.name, argspecs))
    emitln("entry:")
    emitln("  ret i32 "+compileExpr(fd.body))
    emitln("}")

    return result[0]

def compile(sexprs):
    result = ''
    for s in sexprs:
        fd = parseFuncDef(s)
        result += compileFuncDef(fd)
    return result

