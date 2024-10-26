#include "retf_native.h"

void Init_retf_native(void) {
    // We're just going to use
    // the Ruby Zlib module
    // to handle compression.
    //
    // Its not the most efficient
    // but its a lot more battle
    // tested. We can always
    // change it later if its
    // not fast enough.
    rb_require("zlib");

    VALUE mRetf = rb_const_get(rb_cObject, rb_intern("Retf"));

    VALUE mRetfNative = rb_define_module_under(mRetf, "Native");

    rb_define_module_function(mRetfNative, "decode", retf_decode, 2);
    rb_define_module_function(mRetfNative, "encode", retf_encode, 2);
    rb_define_method(rb_cHash, "to_etf", retf_encode_map, 1);
    rb_define_method(rb_cArray, "to_etf", retf_encode_array, 1);
    rb_define_method(rb_cString, "to_etf", retf_encode_string, 1);
    rb_define_method(rb_cFloat, "to_etf", retf_encode_float, 1);
    rb_define_method(rb_cInteger, "to_etf", retf_encode_integer, 1);
    rb_define_method(rb_cClass, "to_etf", retf_encode_class, 1);
    rb_define_method(rb_cSymbol, "to_etf", retf_encode_atom, 1);

    retf_constants_setup(mRetf);
}
