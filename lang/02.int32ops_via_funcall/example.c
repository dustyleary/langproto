extern int add(int a, int b);
extern int sub(int a, int b);
extern int mul(int a, int b);

int scheme_entry(int a, int b) {
    return sub(mul(add(a,b),b),a);
}

