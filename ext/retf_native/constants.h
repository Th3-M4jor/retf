#ifndef RETF_CONSTANTS_H
#define RETF_CONSTANTS_H

#include <ruby.h>

void retf_constants_setup(VALUE mRetf);

// Classes
VALUE retf_constants_get_pid_class(void);
VALUE retf_constants_get_reference_class(void);
VALUE retf_constants_get_tuple_class(void);
VALUE retf_constants_get_bitstring_class(void);

// Strings
VALUE retf_constants_get_elixir_mod_prefix(void);
VALUE retf_constants_get_period(void);
VALUE retf_constants_get_double_colon(void);

// EMPTY FROZEN Array
VALUE retf_constants_get_empty_array(void);

#endif // RETF_CONSTANTS_H
