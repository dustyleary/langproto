#define BINOP(OP, name) int name(int a, int b) { return a OP b; }
BINOP(+, add);
BINOP(-, sub);
BINOP(*, mul);
BINOP(/, div);
BINOP(%, mod);
BINOP(|, bitor);
BINOP(&, bitand);
BINOP(^, bitxor);
BINOP(<<, shl);
BINOP(>>, shr);

unsigned char uchar(int a) {
	unsigned char c = a;
	return c*15;
}

char schar(int a) {
	char c = a;
	return c*15;
}

int scheme_entry(int a, int b) {
    return sub(mul(add(a,b),b),a);
}

