#include <endian.h>
#include <math.h>
#include <ruby.h>
#include <stdint.h>
#include <string.h>
#include <zlib.h>

#include "constants.h"

VALUE retf_encode(VALUE self, VALUE to_encode, VALUE compress);

VALUE retf_encode_integer(int argc, VALUE *argv, VALUE self);
VALUE retf_encode_float(int argc, VALUE *argv, VALUE self);
VALUE retf_encode_string(int argc, VALUE *argv, VALUE self);
VALUE retf_encode_array(int argc, VALUE *argv, VALUE self);
VALUE retf_encode_map(int argc, VALUE *argv, VALUE self);
VALUE retf_encode_atom(int argc, VALUE *argv, VALUE self);
VALUE retf_encode_class(int argc, VALUE *argv, VALUE self);
