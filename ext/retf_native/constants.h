#ifndef RETF_CONSTANTS_H
#define RETF_CONSTANTS_H

#include <ruby.h>

#include "debug.h"

#define RETF_ISIZE_MIN -2147483648
#define RETF_ISIZE_MAX 2147483647

#define RETF_USIZE_MAX 4294967295

// Since not all Rubies we want to support have
// rb_str_strlen, we can work around this by
// calling into Ruby to get the length of a
// string in characters (different from bytes).
#ifdef HAVE_RB_STR_STRLEN
#define RETF_STR_LEN(s) rb_str_strlen(s)
#else
#define RETF_STR_LEN(s) NUM2LONG(rb_funcall(s, rb_intern("size"), 0))
#endif

// Another function not exported by all Rubies
// we want to support is rb_mod_name.
#ifdef HAVE_RB_MOD_NAME
#define RETF_MOD_NAME(m) rb_mod_name(m)
#else
#define RETF_MOD_NAME(m) rb_funcall(m, rb_intern("name"), 0)
#endif

#ifdef HAVE_RB_BIG_EQ
#define RETF_BIG_EQ(a, b) rb_big_eq(a, b)
#else
#define RETF_BIG_EQ(a, b) rb_funcall(a, rb_intern("=="), 1, b)
#endif

#ifdef HAVE_RB_BIG_AND
#define RETF_BIG_AND(a, b) rb_big_and(a, b)
#else
#define RETF_BIG_AND(a, b) rb_funcall(a, rb_intern("&"), 1, b)
#endif

#ifdef HAVE_RB_BIG_RSHIFT
#define RETF_BIG_RSHIFT(a, b) rb_big_rshift(a, b)
#else
#define RETF_BIG_RSHIFT(a, b) rb_funcall(a, rb_intern(">>"), 1, b)
#endif

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

#endif  // RETF_CONSTANTS_H
