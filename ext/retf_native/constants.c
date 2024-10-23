#include "constants.h"

// Classes
VALUE PID_CLASS;
VALUE REFERENCE_CLASS;
VALUE TUPLE_CLASS;
VALUE BITSTRING_CLASS;

// Strings
VALUE ELIXIR_MOD_PREFIX;
VALUE PERIOD;
VALUE DOUBLE_COLON;

// EMPTY FROZEN Array
VALUE EMPTY_ARRAY;

void retf_constants_setup(VALUE mRetf)
{
    PID_CLASS = rb_const_get(mRetf, rb_intern("PID"));
    REFERENCE_CLASS = rb_const_get(mRetf, rb_intern("Reference"));
    TUPLE_CLASS = rb_const_get(mRetf, rb_intern("Tuple"));
    BITSTRING_CLASS = rb_const_get(mRetf, rb_intern("BitBinary"));

    ELIXIR_MOD_PREFIX = rb_interned_str_cstr("Elixir.");
    PERIOD = rb_interned_str_cstr(".");
    DOUBLE_COLON = rb_interned_str_cstr("::");

    EMPTY_ARRAY = rb_ary_new_capa(0);
    rb_ary_freeze(EMPTY_ARRAY);
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

VALUE retf_constants_get_elixir_mod_prefix(void)
{
    return ELIXIR_MOD_PREFIX;
}

VALUE retf_constants_get_period(void)
{
    return PERIOD;
}

VALUE retf_constants_get_double_colon(void)
{
    return DOUBLE_COLON;
}

VALUE retf_constants_get_empty_array(void)
{
    return EMPTY_ARRAY;
}
