#include "constants.h"

// Classes
static VALUE PID_CLASS;
static VALUE REFERENCE_CLASS;
static VALUE TUPLE_CLASS;
static VALUE BITSTRING_CLASS;
static VALUE ZLIB_INFLATE;
static VALUE ZLIB_DEFLATE;

// Symbols
static VALUE STRUCT;

// NOTE: AS_ETF and TO_ETF
// have slightly different
// meanings. AS_ETF is what
// classes should implement
// to return a format that
// will then be encoded
// to ETF. TO_ETF is a method
// that will directly encode
// the object to ETF.
static VALUE AS_ETF;
static VALUE TO_ETF;

void retf_constants_setup(VALUE mRetf)
{
    PID_CLASS = rb_const_get(mRetf, rb_intern("PID"));
    REFERENCE_CLASS = rb_const_get(mRetf, rb_intern("Reference"));
    TUPLE_CLASS = rb_const_get(mRetf, rb_intern("Tuple"));
    BITSTRING_CLASS = rb_const_get(mRetf, rb_intern("BitBinary"));

    VALUE zlib = rb_const_get(rb_cObject, rb_intern("Zlib"));

    ZLIB_INFLATE = rb_const_get(zlib, rb_intern("Inflate"));
    ZLIB_DEFLATE = rb_const_get(zlib, rb_intern("Deflate"));

    STRUCT = rb_intern("__struct__");

    AS_ETF = rb_intern("as_etf");
    TO_ETF = rb_intern("to_etf");
}

VALUE retf_constants_get_pid_class(void)
{
    return PID_CLASS;
}

VALUE retf_constants_get_reference_class(void)
{
    return REFERENCE_CLASS;
}

VALUE retf_constants_get_tuple_class(void)
{
    return TUPLE_CLASS;
}

VALUE retf_constants_get_bitstring_class(void)
{
    return BITSTRING_CLASS;
}

VALUE retf_constants_get_zlib_inflate(void)
{
    return ZLIB_INFLATE;
}

VALUE retf_constants_get_zlib_deflate(void)
{
    return ZLIB_DEFLATE;
}

VALUE retf_constants_get_struct(void)
{
    return STRUCT;
}

VALUE retf_constants_get_as_etf(void)
{
    return AS_ETF;
}

VALUE retf_constants_get_to_etf(void)
{
    return TO_ETF;
}

