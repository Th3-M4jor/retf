#include <endian.h>
#include <ruby.h>
#include <stdint.h>
#include <string.h>
#include <zlib.h>

#include "constants.h"

typedef struct {
    const char* buffer;
    const size_t buffer_size;
    size_t offset;
} decoder_state;

VALUE retf_decode(VALUE self, VALUE str, VALUE skip_version_check);
