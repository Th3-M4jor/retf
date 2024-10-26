#include <ruby.h>
#include <zlib.h>
#include <stdint.h>
#include <string.h>
#include <endian.h>
#include <math.h>

#include "constants.h"

VALUE retf_encode(VALUE self, VALUE to_encode, VALUE compress);
VALUE retf_encode_integer(VALUE self, VALUE str_buffer);
VALUE retf_encode_float(VALUE self, VALUE str_buffer);
VALUE retf_encode_string(VALUE self, VALUE str_buffer);
VALUE retf_encode_array(VALUE self, VALUE str_buffer);
VALUE retf_encode_map(VALUE self, VALUE str_buffer);
VALUE retf_encode_atom(VALUE self, VALUE str_buffer);
VALUE retf_encode_class(VALUE self, VALUE str_buffer);
