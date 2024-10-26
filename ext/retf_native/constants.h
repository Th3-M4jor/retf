#ifndef RETF_CONSTANTS_H
#define RETF_CONSTANTS_H

#include <ruby.h>
#include "debug.h"

#define RETF_ISIZE_MIN -2147483648
#define RETF_ISIZE_MAX 2147483647

#define RETF_USIZE_MAX 4294967295

void retf_constants_setup(VALUE mRetf);

// Classes
VALUE retf_constants_get_pid_class(void);
VALUE retf_constants_get_reference_class(void);
VALUE retf_constants_get_tuple_class(void);
VALUE retf_constants_get_bitstring_class(void);
VALUE retf_constants_get_zlib_inflate(void);
VALUE retf_constants_get_zlib_deflate(void);

// Symbols
VALUE retf_constants_get_struct(void);
VALUE retf_constants_get_as_etf(void);
VALUE retf_constants_get_to_etf(void);

#endif // RETF_CONSTANTS_H
