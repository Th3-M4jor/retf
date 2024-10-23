#include <ruby.h>
#include <zlib.h>
#include <stdint.h>
#include <string.h>
#include <endian.h>

#include "constants.h"

VALUE retf_decode(VALUE self, VALUE str, VALUE skip_version_check);
