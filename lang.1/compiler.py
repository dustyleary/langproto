import sexpr

class FunctionDefinition(object):
    def __init__(self, name, args, body):
        self.name = name
        self.args = args
        self.body = body

def parseFuncDef(s):
    assert isinstance(s, list)
    assert s[0] == sexpr.sym('define')

    assert isinstance(s[1], list)
    assert 1 == len(s[1])
    assert isinstance(s[1][0], sexpr.sym)
    name = s[1][0].txt

    assert isinstance(s[2], int)
    body = s[2]
    return FunctionDefinition(name, [], body)

def compileFuncDef(fd):
    return """
define i32 @%s() nounwind readnone {
entry:
    ret i32 %d
}
""" % (fd.name, fd.body)


def compile(sexprs):
    result = ''
    for s in sexprs:
        fd = parseFuncDef(s)
        result += compileFuncDef(fd)
    return result

