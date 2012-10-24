typedef struct {
  int int_field;
  char char_field;
  double double_field;
} st_blah;

void func_struct_ptr_inout(st_blah* b) {
  b->double_field = b->int_field * 3;
}

st_blah func_struct_return(int param) {
  st_blah result;
  result.int_field = param*3;
  return result;
}

double func_struct_parm(st_blah param) {
  return (param.int_field + param.char_field) * param.double_field;
}
