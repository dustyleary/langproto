#include <stdio.h>
extern int scheme_entry();
int main() {
    printf("%d", scheme_entry());
    return 0;
}


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

