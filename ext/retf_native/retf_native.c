#include "retf_native.h"

void Init_retf_native(void) {
    VALUE mRetf = rb_const_get(rb_cObject, rb_intern("Retf"));

    VALUE mRetfNative = rb_define_module_under(mRetf, "Native");

    rb_define_module_function(mRetfNative, "decode", retf_decode, 2);

    retf_constants_setup(mRetf);
}
