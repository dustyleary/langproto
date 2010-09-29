import string

class sym(object):
    def __init__(self, txt):
        self.txt = txt
    def __repr__(self):
        return "sym(%r)" % self.txt
    def __eq__(self, o):
        try:
            return isinstance(o, sym) and (self.txt == o.txt)
        except Exception:
            return False
    def __ne__(self, o):
        return not (self == o)

def eat_whitespace(txt):
    i = 0
    for i,c in enumerate(txt):
        if c not in string.whitespace:
            return txt[i:]
    return ''

def parse_list(txt):
    txt = eat_whitespace(txt)
    if txt[0] != '(':
        raise Exception('not a list: %r' % txt)

    txt = txt[1:]

    lst = []
    while True:
        txt = eat_whitespace(txt)
        if txt[0] == ')':
            return lst, txt[1:]
        item, txt = parse_item(txt)
        lst.append(item)

terminate_atom = set('()"\'') | set(string.whitespace)

def parse_atom_chars(txt):
    txt = eat_whitespace(txt)
    if txt[0] in terminate_atom:
        raise Exception('not an atom: %r' % txt)
    atom = ''
    for i,c in enumerate(txt):
        if c in terminate_atom:
            return atom, txt[i:]
        else:
            atom += c
    return atom, ''

def parse_atom(txt):
    atom, txt = parse_atom_chars(txt)
    try:
        atom = int(atom)
    except Exception:
        atom = sym(atom)
    return atom, txt

def parse_string(txt):
    txt = eat_whitespace(txt)
    if txt[0] not in '"\'':
        raise Exception('not a string literal: %r' % txt)
    str = ''
    backslash = False
    for i,c in enumerate(txt):
        if i==0: continue
        elif backslash:
            backslash_chars = {'\\': '\\', 'n':'\n'}
            bc = backslash_chars.get(c, None)
            if bc is None:
                raise Exception('%r is not a valid escape sequence' % ('\\'+c))
            str += bc
            backslash = False
        elif c == '\\':
            backslash = True
            if i == len(txt)-1:
                raise Exception('unterminated string literal: %r' % txt)
        elif c == txt[0]:
            return str, txt[i+1:]
        elif c == '\n':
            raise Exception('unterminated string literal: %r' % txt)
        else:
            str += c

def parse_item(txt):
    txt = eat_whitespace(txt)
    for i,c in enumerate(txt):
        if c == '(':
            return parse_list(txt[i:])
        elif c in '"\'':
            return parse_string(txt[i:])
        else:
            return parse_atom(txt[i:])
    raise Exception('unhandled text: %r' % txt)

def parse(txt):
    result = []
    while txt.strip():
        item,txt = parse_item(txt)
        result.append(item)
    return result

def parse1(txt):
    lst = parse(txt)
    if lst:
        return lst[0]

