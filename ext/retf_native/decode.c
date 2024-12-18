#include "decode.h"

static unsigned char decode_byte(decoder_state* state);
static void do_version_check(decoder_state* state);
static VALUE decode_small_atom(decoder_state* state);
static VALUE decode_atom(decoder_state* state);
static uint16_t decode_short(decoder_state* state);
static uint32_t decode_int(decoder_state* state);
static int32_t decode_signed_int(decoder_state* state);
static VALUE decode_float(decoder_state* state);
static VALUE decode_any_atom(decoder_state* state);
static VALUE decode_binary(decoder_state* state);
static VALUE decode_small_tuple(decoder_state* state);
static VALUE decode_large_tuple(decoder_state* state);
static VALUE decode_list(decoder_state* state);
static VALUE decode_erl_string(decoder_state* state);
static VALUE decode_reference(decoder_state* state);
static VALUE decode_pid(decoder_state* state);
static VALUE decode_bit_binary(decoder_state* state);

static VALUE symbolize_string(VALUE str);

static VALUE decode_term(decoder_state* state);

// callback for rb_ensure to free an allocated temporary buffer
static VALUE free_unpack_data(VALUE data);

#ifndef HAVE_RB_HASH_BULK_INSERT
// For TruffleRuby
void rb_hash_bulk_insert(long count, const VALUE *pairs, VALUE hash) {
    long index = 0;
    while (index < count) {
        VALUE name = pairs[index++];
        VALUE value = pairs[index++];
        rb_hash_aset(hash, name, value);
    }
    RB_GC_GUARD(hash);
}
#endif

VALUE retf_decode(VALUE self, VALUE str, VALUE skip_version_check) {
  Check_Type(str, T_STRING);

  char *buffer = RSTRING_PTR(str);
  size_t buffer_size = RSTRING_LEN(str);
  size_t offset = 0;

  decoder_state state = {buffer, buffer_size, offset};

  if (!RTEST(skip_version_check)) {
    do_version_check(&state);
  }

  return decode_term(&state);
}

static void do_version_check(decoder_state* state) {
  unsigned char version = decode_byte(state);

  if (RB_UNLIKELY(version != 131)) {
    rb_raise(rb_eArgError, "malformed ETF");
  }
}

static unsigned char decode_byte(decoder_state* state) {
  if (RB_UNLIKELY(state->offset >= state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  unsigned char b = state->buffer[state->offset];
  state->offset += 1;

  return b;
}

static uint16_t decode_short(decoder_state* state) {
  if (RB_UNLIKELY(state->offset + 2 > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  uint16_t num, short_value;

  num = *(uint16_t *)(state->buffer + state->offset);

  state->offset += 2;

  // It is in network byte order
  short_value = be16toh(num);

  return short_value;
}

static uint32_t decode_int(decoder_state* state) {
  if (RB_UNLIKELY(state->offset + 4 > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  uint32_t num, int_value;

  num = *(uint32_t *)(state->buffer + state->offset);

  // everything is in network (big endian) byte order
  int_value = be32toh(num);

  state->offset += 4;

  return int_value;
}

static int32_t decode_signed_int(decoder_state* state) {
  if (RB_UNLIKELY(state->offset + 4 > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  int32_t num, int_value;

  // everything is in network (big endian) byte order
  num = *(int32_t *)(state->buffer + state->offset);

  int_value = be32toh(num);

  state->offset += 4;

  return int_value;
}

static VALUE decode_float(decoder_state* state) {
  if (RB_UNLIKELY(state->offset + 8 > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  // Doing some pointer magic to load the 8 bytes
  // into a double from Network byte order
  // (big endian) to host byte order
  uint64_t num = *(uint64_t *)(state->buffer + state->offset);
  num = be64toh(num);
  double value;

  // workaround for strict aliasing rules
  memcpy(&value, &num, 8);

  state->offset += 8;

  return DBL2NUM(value);
}

static VALUE decode_small_atom(decoder_state* state) {
  unsigned char length = decode_byte(state);

  if (RB_UNLIKELY(state->offset + length > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  const char *str_ptr = state->buffer + state->offset;
  state->offset += length;

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

static VALUE decode_atom(decoder_state* state) {
  uint_least16_t length = decode_short(state);

  if (RB_UNLIKELY(state->offset + length > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  const char *str_ptr = state->buffer + state->offset;
  state->offset += length;

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

static VALUE decode_any_atom(decoder_state* state) {
  unsigned char tag = decode_byte(state);

  switch (tag) {
    case 115:
    case 119:
      return decode_small_atom(state);
    case 100:
    case 118:
      return decode_atom(state);
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

static VALUE decode_binary(decoder_state* state) {
  uint32_t length = decode_int(state);

  if (RB_UNLIKELY(state->offset + length > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  VALUE str = rb_str_new(state->buffer + state->offset, length);

  state->offset += length;

  return str;
}

static VALUE decode_small_tuple(decoder_state* state) {
  long arity = decode_byte(state);

  VALUE tuple = rb_ary_new_capa(arity);

  for (long i = 0; i < arity; i++) {
    rb_ary_push(tuple, decode_term(state));
  }

  VALUE tuple_class = retf_constants_get_tuple_class();

  return rb_funcall(tuple_class, rb_intern("from_array"), 1, tuple);
}

static VALUE decode_large_tuple(decoder_state* state) {
  uint32_t arity = decode_int(state);

  VALUE tuple = rb_ary_new_capa(arity);

  for (uint32_t i = 0; i < arity; i++) {
    rb_ary_push(tuple, decode_term(state));
  }

  VALUE tuple_class = retf_constants_get_tuple_class();

  return rb_funcall(tuple_class, rb_intern("from_array"), 1, tuple);
}

static VALUE decode_list(decoder_state* state) {
  uint32_t length = decode_int(state);

  VALUE list = rb_ary_new_capa(length + 1);

  for (uint32_t i = 0; i < length + 1; i++) {
    rb_ary_push(list, decode_term(state));
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
static VALUE decode_erl_string(decoder_state* state) {
  uint16_t length = decode_short(state);

  if (RB_UNLIKELY(state->offset + length > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  VALUE str = rb_str_new(state->buffer + state->offset, length);

  state->offset += length;

  return str;
}

static VALUE decode_reference(decoder_state* state) {
  VALUE reference_class = retf_constants_get_reference_class();

  uint16_t size = decode_short(state);
  VALUE node = decode_any_atom(state);
  uint32_t creation = decode_int(state);

  VALUE id = rb_ary_new_capa(size);

  for (uint16_t i = 0; i < size; i++) {
    uint32_t next_id = decode_int(state);
    rb_ary_push(id, INT2FIX(next_id));
  }

  return rb_class_new_instance(3, (VALUE[]){INT2FIX(creation), id, node},
                        reference_class);
}

static VALUE decode_pid(decoder_state* state) {
  VALUE pid_class = retf_constants_get_pid_class();

  VALUE node = decode_any_atom(state);
  uint32_t id = decode_int(state);
  uint32_t serial = decode_int(state);
  uint32_t creation = decode_int(state);

  return rb_class_new_instance(4, (VALUE[]){INT2FIX(id), INT2FIX(serial),
                        INT2FIX(creation), node}, pid_class);
}

static VALUE decode_bit_binary(decoder_state* state) {
  VALUE bitstring_class = retf_constants_get_bitstring_class();

  uint32_t size = decode_int(state);

  unsigned char bits = decode_byte(state);

  if (RB_UNLIKELY(state->offset + size > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  VALUE str = rb_str_new(state->buffer + state->offset, size);

  state->offset += size;

  return rb_class_new_instance(2, (VALUE[]){str, INT2FIX(bits)},
                        bitstring_class);
}

typedef struct {
  const uint32_t map_length;
  VALUE* kvp_arr;
  decoder_state* state;
} map_unpack_data;

static VALUE decode_map_inner(VALUE unpack_data) {
  map_unpack_data* data = (map_unpack_data*) unpack_data;

  VALUE map = rb_hash_new_capa(data->map_length);
  decoder_state* state = data->state;

  VALUE* kvp_arr = data->kvp_arr;

  size_t kvp_arr_len = data->map_length * 2;

  for (uint32_t i = 0; i < kvp_arr_len; i += 2) {
    kvp_arr[i] = decode_term(state);
    kvp_arr[i + 1] = decode_term(state);
  }

  rb_hash_bulk_insert(kvp_arr_len, kvp_arr, map);

  return map;
}

static VALUE decode_map(decoder_state* state) {
  uint32_t length = decode_int(state);

  VALUE* kvp_arr = xmalloc2(length * 2, sizeof(VALUE));

  map_unpack_data data = {length, kvp_arr, state};

  VALUE map =  rb_ensure(decode_map_inner, (VALUE)&data, free_unpack_data, (VALUE)kvp_arr);

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

static VALUE decode_small_bigint(decoder_state* state) {
  unsigned char size = decode_byte(state);
  unsigned char sign = decode_byte(state);

  if (RB_UNLIKELY(state->offset + size > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

  // The rb_big_unpack function expects an array of longs
  // but ETF bigints are stored as an array of bytes.
  size_t bytes_needed = size / sizeof(unsigned long) + (size % sizeof(unsigned long) != 0);

  unsigned long* bytes = xcalloc(bytes_needed, sizeof(unsigned long));

  memcpy(bytes, state->buffer + state->offset, size);

  state->offset += size;

  bigint_unpack_data data = {bytes, bytes_needed, sign};

  return rb_ensure(unpack_bigint, (VALUE)&data, free_unpack_data, (VALUE)bytes);
}

static VALUE decode_large_bigint(decoder_state* state) {
  uint32_t size = decode_int(state);
  unsigned char sign = decode_byte(state);

  if (RB_UNLIKELY(state->offset + size > state->buffer_size)) {
    rb_raise(rb_eArgError, "Unexpected end of input");
  }

 // The rb_big_unpack function expects an array of longs
  // but ETF bigints are stored as an array of bytes.
  size_t bytes_needed = size / sizeof(unsigned long) + (size % sizeof(unsigned long) != 0);

  unsigned long* bytes = xcalloc(bytes_needed, sizeof(unsigned long));

  memcpy(bytes, state->buffer + state->offset, size);

  state->offset += size;

  bigint_unpack_data data = {bytes, bytes_needed, sign};

  return rb_ensure(unpack_bigint, (VALUE)&data, free_unpack_data, (VALUE)bytes);
}

static VALUE decompress_data(decoder_state* state) {
  uint32_t uncompressed_size = decode_int(state);

  VALUE zipped_str = rb_str_new(state->buffer + state->offset, state->buffer_size - state->offset);

  VALUE uncompressed_data = rb_funcall(retf_constants_get_zlib_inflate(),
                                       rb_intern("inflate"), 1, zipped_str);

  size_t new_buffer_size = RSTRING_LEN(uncompressed_data);

  if (RB_UNLIKELY(new_buffer_size != uncompressed_size)) {
    rb_raise(rb_eArgError,
             "Decompressed data size does not match expected size");
  }

  size_t new_offset = 0;
  const char *new_buffer = RSTRING_PTR(uncompressed_data);

  decoder_state new_state = {new_buffer, new_buffer_size, new_offset};

  VALUE term = decode_term(&new_state);

  RB_GC_GUARD(uncompressed_data);

  return term;
}

static VALUE decode_term(decoder_state* state) {
  unsigned char tag = decode_byte(state);

  switch (tag) {
    case 118:
    case 100:
      return decode_atom(state);
    case 119:
    case 115:
      return decode_small_atom(state);
    case 109:
      return decode_binary(state);
    case 97:;
      long byte = decode_byte(state);
      return LONG2FIX(byte);
    case 98:;
      long num = decode_signed_int(state);
      return LONG2FIX(num);
    case 116:
      return decode_map(state);
    case 104:
      return decode_small_tuple(state);
    case 70:
      return decode_float(state);
    case 108:
      return decode_list(state);
    case 106:
      // 106 is for an empty list
      return rb_ary_new();
    case 107:
      return decode_erl_string(state);
    case 110:
      return decode_small_bigint(state);
    case 111:
      return decode_large_bigint(state);
    case 88:
      return decode_pid(state);
    case 90:
      return decode_reference(state);
    case 105:
      return decode_large_tuple(state);
    case 77:
      return decode_bit_binary(state);
    case 80:
      return decompress_data(state);
    default:
      rb_raise(rb_eArgError, "unexpected tag: %u", (unsigned int)tag);
  }

  // Should never get here
  return Qnil;
}
