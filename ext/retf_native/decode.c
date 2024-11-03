#include "decode.h"

static unsigned char decode_byte(char *buffer, size_t buffer_size,
                                 size_t *offset);
static void do_version_check(char *buffer, size_t buffer_size, size_t *offset);
static VALUE decode_small_atom(char *buffer, size_t buffer_size,
                               size_t *offset);
static VALUE decode_atom(char *buffer, size_t buffer_size, size_t *offset);
static uint16_t decode_short(char *buffer, size_t buffer_size, size_t *offset);
static uint32_t decode_int(char *buffer, size_t buffer_size, size_t *offset);
static int32_t decode_signed_int(char *buffer, size_t buffer_size,
                                 size_t *offset);
static VALUE decode_float(char *buffer, size_t buffer_size, size_t *offset);
static VALUE decode_any_atom(char *buffer, size_t buffer_size, size_t *offset);
static VALUE decode_binary(char *buffer, size_t buffer_size, size_t *offset);
static VALUE decode_small_tuple(char *buffer, size_t buffer_size,
                                size_t *offset);
static VALUE decode_large_tuple(char *buffer, size_t buffer_size,
                                size_t *offset);
static VALUE decode_list(char *buffer, size_t buffer_size, size_t *offset);
static VALUE decode_erl_string(char *buffer, size_t buffer_size,
                               size_t *offset);
static VALUE decode_reference(char *buffer, size_t buffer_size, size_t *offset);
static VALUE decode_pid(char *buffer, size_t buffer_size, size_t *offset);
static VALUE decode_bit_binary(char *buffer, size_t buffer_size,
                               size_t *offset);

static VALUE symbolize_string(VALUE str);

static VALUE decode_term(char *buffer, size_t buffer_size, size_t *offset);

VALUE retf_decode(VALUE self, VALUE str, VALUE skip_version_check) {
  Check_Type(str, T_STRING);

  char *buffer = RSTRING_PTR(str);
  size_t buffer_size = RSTRING_LEN(str);
  size_t offset = 0;

  if (!RTEST(skip_version_check)) {
    do_version_check(buffer, buffer_size, &offset);
  }

  return decode_term(buffer, buffer_size, &offset);
}

static void do_version_check(char *buffer, size_t buffer_size, size_t *offset) {
  unsigned char version = decode_byte(buffer, buffer_size, offset);

  if (RB_UNLIKELY(version != 131)) {
    rb_raise(rb_eArgError, "malformed ETF");
  }
}

static unsigned char decode_byte(char *buffer, size_t buffer_size,
                                 size_t *offset) {
  if (RB_UNLIKELY(*offset >= buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  unsigned char b = buffer[*offset];
  *offset += 1;

  return b;
}

static uint16_t decode_short(char *buffer, size_t buffer_size, size_t *offset) {
  if (RB_UNLIKELY(*offset + 2 > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  uint16_t num, short_value;

  num = *(uint16_t *)(buffer + *offset);

  *offset += 2;

  // It is in network byte order
  short_value = be16toh(num);

  return short_value;
}

static uint32_t decode_int(char *buffer, size_t buffer_size, size_t *offset) {
  if (RB_UNLIKELY(*offset + 4 > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  uint32_t num, int_value;

  num = *(uint32_t *)(buffer + *offset);

  // everything is in network (big endian) byte order
  int_value = be32toh(num);

  *offset += 4;

  return int_value;
}

static int32_t decode_signed_int(char *buffer, size_t buffer_size,
                                 size_t *offset) {
  if (RB_UNLIKELY(*offset + 4 > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  int32_t num, int_value;

  // everything is in network (big endian) byte order
  num = *(int32_t *)(buffer + *offset);

  int_value = be32toh(num);

  *offset += 4;

  return int_value;
}

static VALUE decode_float(char *buffer, size_t buffer_size, size_t *offset) {
  if (RB_UNLIKELY(*offset + 8 > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  // Doing some pointer magic to load the 8 bytes
  // into a double from Network byte order
  // (big endian) to host byte order
  uint64_t num = *(uint64_t *)(buffer + *offset);
  num = be64toh(num);
  double value;

  // workaround for strict aliasing rules
  memcpy(&value, &num, 8);

  *offset += 8;

  return DBL2NUM(value);
}

static VALUE decode_small_atom(char *buffer, size_t buffer_size,
                               size_t *offset) {
  unsigned char length = decode_byte(buffer, buffer_size, offset);

  if (RB_UNLIKELY(*offset + length > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  char *str_ptr = buffer + *offset;
  *offset += length;

  if (length == 4 && memcmp(str_ptr, "true", 4) == 0) {
    return Qtrue;
  } else if (length == 5 && memcmp(str_ptr, "false", 5) == 0) {
    return Qfalse;
  } else if (length == 3 && memcmp(str_ptr, "nil", 4) == 0) {
    return Qnil;
  }

  VALUE str = rb_utf8_str_new(str_ptr, length);

  return symbolize_string(str);
}

static VALUE decode_atom(char *buffer, size_t buffer_size, size_t *offset) {
  uint_least16_t length = decode_short(buffer, buffer_size, offset);

  if (RB_UNLIKELY(*offset + length > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  char *str_ptr = buffer + *offset;
  *offset += length;

  if (length == 4 && memcmp(str_ptr, "true", 4) == 0) {
    return Qtrue;
  } else if (length == 5 && memcmp(str_ptr, "false", 5) == 0) {
    return Qfalse;
  } else if (length == 3 && memcmp(str_ptr, "nil", 4) == 0) {
    return Qnil;
  }

  VALUE str = rb_utf8_str_new(str_ptr, length);

  return symbolize_string(str);
}

static VALUE decode_any_atom(char *buffer, size_t buffer_size, size_t *offset) {
  unsigned char tag = decode_byte(buffer, buffer_size, offset);

  switch (tag) {
    case 115:
    case 119:
      return decode_small_atom(buffer, buffer_size, offset);
    case 100:
    case 118:
      return decode_atom(buffer, buffer_size, offset);
    default:
      rb_raise(rb_eArgError, "expected an atom tag, got %u", (unsigned int)tag);
  }
}

static VALUE symbolize_string(VALUE str) {
  Check_Type(str, T_STRING);

  char *c_str = RSTRING_PTR(str);
  size_t c_str_len = RSTRING_LEN(str);

  if (c_str_len <= 7 || memcmp(c_str, "Elixir.", 7) != 0) {
    return rb_to_symbol(str);
  }

  // confirmed we have something that looks like it could
  // be an Elixir module. Let's try to "rubify" it.
  //
  // Not spending too much time on making this efficient
  // as its likely not the most common case.

  VALUE prefix_deleted = rb_utf8_str_new(c_str + 7, c_str_len - 7);

  VALUE rubified = rb_funcall(prefix_deleted, rb_intern("gsub"), 2,
                              rb_str_new_lit("."), rb_str_new_lit("::"));

  VALUE defined =
      rb_funcall(rb_cObject, rb_intern("const_defined?"), 1, rubified);

  if (RTEST(defined)) {
    return rb_funcall(rb_cObject, rb_intern("const_get"), 1, rubified);
  } else {
    return rb_to_symbol(str);
  }
}

static VALUE decode_binary(char *buffer, size_t buffer_size, size_t *offset) {
  uint32_t length = decode_int(buffer, buffer_size, offset);

  if (RB_UNLIKELY(*offset + length > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  VALUE str = rb_str_new(buffer + *offset, length);

  *offset += length;

  return str;
}

static VALUE decode_small_tuple(char *buffer, size_t buffer_size,
                                size_t *offset) {
  long arity = decode_byte(buffer, buffer_size, offset);

  VALUE tuple = rb_ary_new_capa(arity);

  for (long i = 0; i < arity; i++) {
    rb_ary_push(tuple, decode_term(buffer, buffer_size, offset));
  }

  VALUE tuple_class = retf_constants_get_tuple_class();

  return rb_funcall(tuple_class, rb_intern("from_array"), 1, tuple);
}

static VALUE decode_large_tuple(char *buffer, size_t buffer_size,
                                size_t *offset) {
  uint32_t arity = decode_int(buffer, buffer_size, offset);

  VALUE tuple = rb_ary_new_capa(arity);

  for (uint32_t i = 0; i < arity; i++) {
    rb_ary_push(tuple, decode_term(buffer, buffer_size, offset));
  }

  VALUE tuple_class = retf_constants_get_tuple_class();

  return rb_funcall(tuple_class, rb_intern("from_array"), 1, tuple);
}

static VALUE decode_list(char *buffer, size_t buffer_size, size_t *offset) {
  uint32_t length = decode_int(buffer, buffer_size, offset);

  VALUE list = rb_ary_new_capa(length + 1);

  for (uint32_t i = 0; i < length + 1; i++) {
    rb_ary_push(list, decode_term(buffer, buffer_size, offset));
  }

  // For proper erlang lists the last element should be
  // an empty list; If so, we'll remove it.
  VALUE tail = rb_ary_entry(list, length);

  if (TYPE(tail) == T_ARRAY && rb_array_len(tail) == 0) {
    rb_ary_pop(list);
  }

  return list;
}

// This is for erlang style "strings" which are just a list of
// integers that each fit in a byte.
static VALUE decode_erl_string(char *buffer, size_t buffer_size,
                               size_t *offset) {
  uint16_t length = decode_short(buffer, buffer_size, offset);

  if (RB_UNLIKELY(*offset + length > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  VALUE str = rb_str_new(buffer + *offset, length);

  *offset += length;

  return str;
}

static VALUE decode_reference(char *buffer, size_t buffer_size,
                              size_t *offset) {
  VALUE reference_class = retf_constants_get_reference_class();

  uint16_t size = decode_short(buffer, buffer_size, offset);
  VALUE node = decode_any_atom(buffer, buffer_size, offset);
  uint32_t creation = decode_int(buffer, buffer_size, offset);

  VALUE id = rb_ary_new_capa(size);

  for (uint16_t i = 0; i < size; i++) {
    uint32_t next_id = decode_int(buffer, buffer_size, offset);
    rb_ary_push(id, INT2FIX(next_id));
  }

  return rb_class_new_instance(3, (VALUE[]){INT2FIX(creation), id, node},
                        reference_class);
}

static VALUE decode_pid(char *buffer, size_t buffer_size, size_t *offset) {
  VALUE pid_class = retf_constants_get_pid_class();

  VALUE node = decode_any_atom(buffer, buffer_size, offset);
  uint32_t id = decode_int(buffer, buffer_size, offset);
  uint32_t serial = decode_int(buffer, buffer_size, offset);
  uint32_t creation = decode_int(buffer, buffer_size, offset);

  return rb_class_new_instance(4, (VALUE[]){INT2FIX(id), INT2FIX(serial),
                        INT2FIX(creation), node}, pid_class);
}

static VALUE decode_bit_binary(char *buffer, size_t buffer_size,
                               size_t *offset) {
  VALUE bitstring_class = retf_constants_get_bitstring_class();

  uint32_t size = decode_int(buffer, buffer_size, offset);

  unsigned char bits = decode_byte(buffer, buffer_size, offset);

  if (RB_UNLIKELY(*offset + size > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  VALUE str = rb_str_new(buffer + *offset, size);

  *offset += size;

  return rb_class_new_instance(2, (VALUE[]){str, INT2FIX(bits)},
                        bitstring_class);
}

static VALUE decode_map(char *buffer, size_t buffer_size, size_t *offset) {
  uint32_t length = decode_int(buffer, buffer_size, offset);

  VALUE map = rb_hash_new_capa(length);

  for (uint32_t i = 0; i < length; i++) {
    VALUE key = decode_term(buffer, buffer_size, offset);
    VALUE value = decode_term(buffer, buffer_size, offset);

    rb_hash_aset(map, key, value);
  }

  VALUE struct_sym = retf_constants_get_struct();

  VALUE struct_class = rb_hash_aref(map, rb_id2sym(struct_sym));

  if (RTEST(struct_class) &&
      rb_respond_to(struct_class, rb_intern("from_etf"))) {
    VALUE struct_instance =
        rb_funcall(struct_class, rb_intern("from_etf"), 1, map);
    return struct_instance;
  }

  return map;
}

typedef struct {
  unsigned long* bytes;
  size_t bytes_len;
  unsigned char sign;
} bigint_unpack_data;

#ifdef HAVE_RB_BIG_UNPACK
static VALUE unpack_bigint(VALUE data) {
  bigint_unpack_data* unpack_data = (bigint_unpack_data*)data;

  VALUE num = rb_big_unpack(unpack_data->bytes, unpack_data->bytes_len);

  if (unpack_data->sign != 0) {
    num = rb_funcall(num, rb_intern("*"), 1, INT2FIX(-1));
  }

  return num;
}
#else
static VALUE unpack_bigint(VALUE data) {
  bigint_unpack_data* unpack_data = (bigint_unpack_data*)data;

  VALUE num = INT2FIX(0);
  VALUE two_fifty_six = INT2FIX(256);

  unsigned char* buffer = (unsigned char*)unpack_data->bytes;
  size_t size = unpack_data->bytes_len * sizeof(unsigned long);

  for (size_t i = 0; i < size; i++) {
    unsigned char b = buffer[i];
    VALUE byte_value = INT2FIX(b);
    VALUE idx = INT2FIX(i);

    VALUE powed = rb_funcall(two_fifty_six, rb_intern("**"), 1, idx);
    VALUE shifted = rb_funcall(byte_value, rb_intern("*"), 1, powed);
    num = rb_funcall(num, rb_intern("+"), 1, shifted);
  }

  if (unpack_data->sign != 0) {
    num = rb_funcall(num, rb_intern("*"), 1, INT2FIX(-1));
  }

  return num;
}
#endif

// This is a callback function for rb_ensure
static VALUE free_unpack_data(VALUE data) {
  xfree((void*) data);
  return Qnil;
}

static VALUE decode_small_bigint(char *buffer, size_t buffer_size,
                                 size_t *offset) {
  unsigned char size = decode_byte(buffer, buffer_size, offset);
  unsigned char sign = decode_byte(buffer, buffer_size, offset);

  if (RB_UNLIKELY(*offset + size > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  // The rb_big_unpack function expects an array of longs
  // but ETF bigints are stored as an array of bytes.
  size_t bytes_needed = size / sizeof(unsigned long) + (size % sizeof(unsigned long) != 0);

  unsigned long* bytes = xcalloc(bytes_needed, sizeof(unsigned long));

  memcpy(bytes, buffer + *offset, size);

  *offset += size;

  bigint_unpack_data data = {bytes, bytes_needed, sign};

  return rb_ensure(unpack_bigint, (VALUE)&data, free_unpack_data, (VALUE)bytes);
}

static VALUE decode_large_bigint(char *buffer, size_t buffer_size,
                                 size_t *offset) {
  uint32_t size = decode_int(buffer, buffer_size, offset);
  unsigned char sign = decode_byte(buffer, buffer_size, offset);

  if (RB_UNLIKELY(*offset + size > buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

 // The rb_big_unpack function expects an array of longs
  // but ETF bigints are stored as an array of bytes.
  size_t bytes_needed = size / sizeof(unsigned long) + (size % sizeof(unsigned long) != 0);

  unsigned long* bytes = xcalloc(bytes_needed, sizeof(unsigned long));

  memcpy(bytes, buffer + *offset, size);

  *offset += size;

  bigint_unpack_data data = {bytes, bytes_needed, sign};

  return rb_ensure(unpack_bigint, (VALUE)&data, free_unpack_data, (VALUE)bytes);
}

static VALUE decompress_data(char *buffer, size_t buffer_size, size_t *offset) {
  uint32_t uncompressed_size = decode_int(buffer, buffer_size, offset);

  VALUE zipped_str = rb_str_new(buffer + *offset, buffer_size - *offset);

  VALUE uncompressed_data = rb_funcall(retf_constants_get_zlib_inflate(),
                                       rb_intern("inflate"), 1, zipped_str);

  size_t new_buffer_size = RSTRING_LEN(uncompressed_data);

  if (RB_UNLIKELY(new_buffer_size != uncompressed_size)) {
    rb_raise(rb_eArgError,
             "Decompressed data size does not match expected size");
  }

  size_t new_offset = 0;
  char *new_buffer = RSTRING_PTR(uncompressed_data);

  return decode_term(new_buffer, new_buffer_size, &new_offset);
}

static VALUE decode_term(char *buffer, size_t buffer_size, size_t *offset) {
  unsigned char tag = decode_byte(buffer, buffer_size, offset);

  switch (tag) {
    case 118:
    case 100:
      return decode_atom(buffer, buffer_size, offset);
    case 119:
    case 115:
      return decode_small_atom(buffer, buffer_size, offset);
    case 109:
      return decode_binary(buffer, buffer_size, offset);
    case 97:;
      long byte = decode_byte(buffer, buffer_size, offset);
      return LONG2FIX(byte);
    case 98:;
      long num = decode_signed_int(buffer, buffer_size, offset);
      return LONG2FIX(num);
    case 116:
      return decode_map(buffer, buffer_size, offset);
    case 104:
      return decode_small_tuple(buffer, buffer_size, offset);
    case 70:
      return decode_float(buffer, buffer_size, offset);
    case 108:
      return decode_list(buffer, buffer_size, offset);
    case 106:
      // 106 is for an empty list
      return rb_ary_new();
    case 107:
      return decode_erl_string(buffer, buffer_size, offset);
    case 110:
      return decode_small_bigint(buffer, buffer_size, offset);
    case 111:
      return decode_large_bigint(buffer, buffer_size, offset);
    case 88:
      return decode_pid(buffer, buffer_size, offset);
    case 90:
      return decode_reference(buffer, buffer_size, offset);
    case 105:
      return decode_large_tuple(buffer, buffer_size, offset);
    case 77:
      return decode_bit_binary(buffer, buffer_size, offset);
    case 80:
      return decompress_data(buffer, buffer_size, offset);
    default:
      rb_raise(rb_eArgError, "unexpected tag: %u", (unsigned int)tag);
  }

  // Should never get here
  return Qnil;
}
