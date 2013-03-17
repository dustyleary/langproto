typedef struct {
  int int_field;
  char char_field;
  double double_field;
} st_blah;

int* ptr_to_stack(int n) {
  return &n;
}

void func_struct_ptr_inout(st_blah* b) {
  b->double_field = b->int_field * 3;
}

st_blah func_struct_return(int iparm, char cparm) {
  st_blah result;
  result.int_field = iparm*3;
  result.char_field = cparm*7;
  return result;
}

double func_struct_parm(st_blah param) {
  return (param.int_field + param.char_field) * param.double_field;
}
