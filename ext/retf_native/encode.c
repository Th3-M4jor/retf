#include "encode.h"

static VALUE encode_fixed_integer(long val, VALUE str_buffer);
static VALUE encode_big_integer(VALUE bigint, VALUE str_buffer);
static VALUE encode_any_integer(VALUE self, VALUE str_buffer);
static VALUE encode_float(VALUE self, VALUE str_buffer);
static VALUE encode_string(VALUE self, VALUE str_buffer);
static VALUE encode_array(VALUE self, VALUE str_buffer);
static VALUE encode_map(VALUE self, VALUE str_buffer);
static VALUE encode_atom(VALUE self, VALUE str_buffer);
static VALUE encode_class(VALUE self, VALUE str_buffer);
static VALUE encode_object(VALUE self, VALUE str_buffer);

static int encode_hash_pair(VALUE key, VALUE value, VALUE buffer);
static VALUE compress_data(VALUE str_buffer);
static VALUE encode_term(VALUE term, VALUE str_buffer);

// Helper function to deduplicate the logic of scanning arguments
// and calling the actual encoding function.
static inline VALUE scan_and_call(int argc, VALUE *argv, VALUE self,
                           VALUE (*func)(VALUE self, VALUE str_buffer)) {
  VALUE str_buffer;

  rb_scan_args(argc, argv, "01", &str_buffer);

  if (argc == 0) {
    str_buffer = rb_str_buf_new(10);
  } else {
    Check_Type(str_buffer, T_STRING);
  }

  return func(self, str_buffer);
}

VALUE retf_encode(VALUE self, VALUE to_encode, VALUE compress) {
  VALUE str_buffer = rb_str_buf_new(100);

  if (RTEST(compress)) {
    encode_term(to_encode, str_buffer);
    return compress_data(str_buffer);
  }

  rb_str_cat(str_buffer, "\x83", 1);
  encode_term(to_encode, str_buffer);

  return str_buffer;
}

static inline void ensure_str_extra_capacity(VALUE str, size_t required) {
  size_t cap = rb_str_capacity(str);
  size_t len = RSTRING_LEN(str);

  if (len + required < cap) {
    rb_str_modify_expand(str, required);
  }
}

static VALUE compress_data(VALUE str_buffer) {
  size_t len = RSTRING_LEN(str_buffer);

  if (len > RETF_USIZE_MAX) {
    rb_raise(rb_eArgError,
             "encoded data is too large length must fit in a "
             "32-bit unsigned integer");
  }

  uint32_t nlen = htobe32(len);

  // compress the data
  VALUE zipped_str = rb_funcall(retf_constants_get_zlib_deflate(),
                                rb_intern("deflate"), 1, str_buffer);

  VALUE out_str = rb_str_buf_new(6 + RSTRING_LEN(zipped_str));
  rb_str_cat(out_str, "\x83\x50", 2);
  rb_str_cat(out_str, (char *)&nlen, 4);
  return rb_str_concat(out_str, zipped_str);
}

static VALUE encode_term(VALUE term, VALUE str_buffer) {
  int t = TYPE(term);

  switch (t) {
    case T_NIL:
      return rb_str_cat(str_buffer, "w\003nil", 5);
    case T_TRUE:
      return rb_str_cat(str_buffer, "w\004true", 6);
    case T_FALSE:
      return rb_str_cat(str_buffer, "w\005false", 7);
    case T_FIXNUM:
      return encode_fixed_integer(FIX2LONG(term), str_buffer);
    case T_BIGNUM:
      return encode_big_integer(term, str_buffer);
    case T_FLOAT:
      return encode_float(term, str_buffer);
    case T_STRING:
      return encode_string(term, str_buffer);
    case T_ARRAY:
      return encode_array(term, str_buffer);
    case T_HASH:
      return encode_map(term, str_buffer);
    case T_SYMBOL:
      return encode_atom(term, str_buffer);
    case T_CLASS:
    case T_MODULE:
      return encode_class(term, str_buffer);
    case T_OBJECT:
      return encode_object(term, str_buffer);
    default:
      rb_raise(rb_eArgError, "unsupported type for encoding");
  }

  return Qnil;
}

VALUE retf_encode_integer(int argc, VALUE *argv, VALUE self) {
  return scan_and_call(argc, argv, self, encode_any_integer);
}

static VALUE encode_any_integer(VALUE self, VALUE str_buffer) {
  if (TYPE(self) == T_FIXNUM) {
    return encode_fixed_integer(FIX2LONG(self), str_buffer);
  }

  return encode_big_integer(self, str_buffer);
}

static VALUE encode_big_integer(VALUE bigint, VALUE str_buffer) {
  // large integer encoding... yaayyyy
  char sign = rb_big_sign(bigint) == 0 ? 1 : 0;

  if (sign == 1) {
    bigint = rb_funcall(bigint, rb_intern("abs"), 0);
  }

  // going with a length of 11 bytes
  // since we likely won't be encoding
  // anything larger than that for the
  // most part.
  VALUE str = rb_str_buf_new(11);

  long len = 0;

  while (!RTEST(RETF_BIG_EQ(bigint, INT2FIX(0)))) {
    if (RB_TYPE_P(bigint, T_FIXNUM)) {
      break;
    }

    char byte = FIX2INT(RETF_BIG_AND(bigint, INT2FIX(0xFF)));
    bigint = RETF_BIG_RSHIFT(bigint, INT2FIX(8));

    rb_str_cat(str, &byte, 1);
    len++;
  }

  // At some point rb_big_rshift may return a fixnum
  // so we need to handle that case as well.
  if(RB_TYPE_P(bigint, T_FIXNUM)) {
    long long bigint_val = FIX2LONG(bigint);

    while (bigint_val > 0) {
      char byte = bigint_val & 0xFF;
      bigint_val >>= 8;

      rb_str_cat(str, &byte, 1);
      len++;
    }
  }

  if(len < 256) {
    unsigned char new_len = len;
    rb_str_cat(str_buffer, "\x6E", 1);
    rb_str_cat(str_buffer, (char *)&new_len, 1);
  } else {
    uint32_t new_len = htobe32(len);
    rb_str_cat(str_buffer, "\x6F", 1);
    rb_str_cat(str_buffer, (char *)&new_len, 4);
  }

  rb_str_cat(str_buffer, &sign, 1);
  return rb_str_concat(str_buffer, str);
}

static VALUE encode_fixed_integer(long val, VALUE str_buffer) {
  if (val >= 0 && val < 256) {
    rb_str_cat(str_buffer, "\x61", 1);
    return rb_str_cat(str_buffer, (char *)&val, 1);
  }

  if (val >= RETF_ISIZE_MIN && val <= RETF_ISIZE_MAX) {
    rb_str_cat(str_buffer, "\x62", 1);

    int32_t nval = htobe32(val);

    return rb_str_cat(str_buffer, (char *)&nval, 4);
  }

  // large integer encoding... yaayyyy
  char sign = val < 0 ? 1 : 0;

  long abs_val = labs(val);

  // Instead of shifting the bits to find the number of bytes
  // we can just use log2 to find the number of bits
  // and then divide by 8 to get the number of bytes
  // rounding up.
  long count = (long) ceil(log2(abs_val));
  char bytes = count / 8 + (count % 8 == 0 ? 0 : 1);

  // Since the bytes go least significant first
  // we need to convert the number to little endian.
  uint64_t encoded = htole64(abs_val);

  rb_str_cat(str_buffer, "\x6E", 1);
  rb_str_cat(str_buffer, &bytes, 1);
  rb_str_cat(str_buffer, &sign, 1);

  // Only write the bytes we need rather than the full 8
  return rb_str_cat(str_buffer, (char *)&encoded, bytes);
}

VALUE retf_encode_float(int argc, VALUE *argv, VALUE self) {
  return scan_and_call(argc, argv, self, encode_float);
}

static VALUE encode_float(VALUE self, VALUE str_buffer) {
  double to_encode = rb_float_value(self);

  if (!isfinite(to_encode)) {
    rb_raise(rb_eArgError, "only floats with a finite value can be encoded");
  }

  rb_str_cat(str_buffer, "\x46", 1);

  uint64_t num;
  memcpy(&num, &to_encode, 8);
  num = htobe64(num);

  return rb_str_cat(str_buffer, (char *)&num, 8);
}

VALUE retf_encode_string(int argc, VALUE *argv, VALUE self) {
  return scan_and_call(argc, argv, self, encode_string);
}

static VALUE encode_string(VALUE self, VALUE str_buffer) {
  size_t len = RSTRING_LEN(self);

  if (len > RETF_USIZE_MAX) {
    rb_raise(rb_eArgError,
             "string is too long to encode, bytesize must "
             "fit in a 32-bit unsigned integer");
  }

  ensure_str_extra_capacity(str_buffer, 5 + len);

  uint32_t nlen = htobe32(len);

  rb_str_cat(str_buffer, "\x6D", 1);
  rb_str_cat(str_buffer, (char *)&nlen, 4);
  return rb_str_cat(str_buffer, RSTRING_PTR(self), len);
}

VALUE retf_encode_array(int argc, VALUE *argv, VALUE self) {
  return scan_and_call(argc, argv, self, encode_array);
}

static VALUE encode_array(VALUE self, VALUE str_buffer) {
  long len = rb_array_len(self);

  if (RB_UNLIKELY(len > RETF_USIZE_MAX)) {
    rb_raise(rb_eArgError,
             "array is too long to encode, length must fit "
             "in a 32-bit unsigned integer");
  }

  if (len == 0) {
    // Empty list code
    return rb_str_cat(str_buffer, "\x6A", 1);
  }

  ensure_str_extra_capacity(str_buffer, 5 + len);

  // 108 is the list tag
  rb_str_cat(str_buffer, "\x6C", 1);

  uint32_t nlen = htobe32(len);

  rb_str_cat(str_buffer, (char *)&nlen, 4);

  for (long i = 0; i < len; i++) {
    VALUE elem = rb_ary_entry(self, i);
    encode_term(elem, str_buffer);
  }

  // 106 is the empty list tag
  // properly formatted lists should end with an empty list
  return rb_str_cat(str_buffer, "\x6A", 1);
}

VALUE retf_encode_map(int argc, VALUE *argv, VALUE self) {
  return scan_and_call(argc, argv, self, encode_map);
}

static VALUE encode_map(VALUE self, VALUE str_buffer) {
  size_t size = RHASH_SIZE(self);

  if (RB_UNLIKELY(size > RETF_USIZE_MAX)) {
    rb_raise(rb_eArgError,
             "map is too large to encode, size must fit in a "
             "32-bit unsigned integer");
  }

  ensure_str_extra_capacity(str_buffer, 5 + (size * 2));

  // 116 is the map tag
  rb_str_cat(str_buffer, "\x74", 1);

  uint32_t nsize = htobe32(size);

  rb_str_cat(str_buffer, (char *)&nsize, 4);

  rb_hash_foreach(self, encode_hash_pair, str_buffer);

  return str_buffer;
}

static int encode_hash_pair(VALUE key, VALUE value, VALUE buffer) {  
  encode_term(key, buffer);
  encode_term(value, buffer);
  return ST_CONTINUE;
}

static VALUE encode_object(VALUE self, VALUE str_buffer) {
  // For classes which don't encode to Elixir Struct-like
  // maps, they can instead implement `to_etf`
  // which will be called to encode the object.
  VALUE to_etf_sym = retf_constants_get_to_etf();
  if (rb_respond_to(self, to_etf_sym)) {
    return rb_funcall(self, to_etf_sym, 1, str_buffer);
  }

  VALUE as_etf_sym = retf_constants_get_as_etf();

  if (!rb_respond_to(self, as_etf_sym)) {
    rb_raise(rb_eArgError, "object does not respond to `as_etf`");
  }

  VALUE hash_to_encode = rb_funcall(self, as_etf_sym, 0);

  Check_Type(hash_to_encode, T_HASH);

  // We're duplicating the code for encoding a map here
  // so we can save the added cost of calling the function
  // to add `__struct__: self.class` to the map.

  uint64_t size = RHASH_SIZE(hash_to_encode);

  size += 1;

  if (size > RETF_USIZE_MAX) {
    rb_raise(rb_eArgError,
             "map is too large to encode, size must fit in a "
             "32-bit unsigned integer");
  }

  ensure_str_extra_capacity(str_buffer, 5 + (size * 2));

  // 116 is the map tag
  rb_str_cat(str_buffer, "\x74", 1);

  uint32_t nsize = htobe32(size);

  rb_str_cat(str_buffer, (char *)&nsize, 4);

  rb_str_cat(str_buffer, "\x77\x0A__struct__", 12);

  VALUE class = rb_obj_class(self);
  encode_class(class, str_buffer);

  rb_hash_foreach(hash_to_encode, encode_hash_pair, str_buffer);

  return str_buffer;
}

VALUE retf_encode_atom(int argc, VALUE *argv, VALUE self) {
  return scan_and_call(argc, argv, self, encode_atom);
}

static VALUE encode_atom(VALUE self, VALUE str_buffer) {
  VALUE str = rb_sym2str(self);
  size_t len = RSTRING_LEN(str);
  char *ptr = RSTRING_PTR(str);

  if (RETF_STR_LEN(str) > 255) {
    rb_raise(rb_eArgError,
             "atom is too long to encode, length must fit in "
             "a 32-bit unsigned integer");
  }

  // This may seen a bit weird, but that's because atoms can be
  // utf-8 encoded and this is the length in bytes.
  // The check above was the length in characters.
  if (len < 256) {
    char new_len = len;
    ensure_str_extra_capacity(str_buffer, 2 + len);
    rb_str_cat(str_buffer, "\x77", 1);
    rb_str_cat(str_buffer, (char *)&new_len, 1);
    return rb_str_cat(str_buffer, ptr, len);
  } else {
    ensure_str_extra_capacity(str_buffer, 3 + len);
    rb_str_cat(str_buffer, "\x76", 1);

    uint16_t nlen = htobe16(len);

    rb_str_cat(str_buffer, (char *)&nlen, 2);
    return rb_str_cat(str_buffer, ptr, len);
  }
}

VALUE retf_encode_class(int argc, VALUE *argv, VALUE self) {
  return scan_and_call(argc, argv, self, encode_class);
}

static VALUE encode_class(VALUE self, VALUE str_buffer) {
  VALUE name = RETF_MOD_NAME(self);

  if (RB_NIL_P(name)) {
    rb_raise(rb_eArgError, "cannot encode an anonymous class");
  }

  // Replace the double colon with a period
  // and prepend the Elixir module prefix

  VALUE elixirized = rb_funcall(name, rb_intern("gsub"), 2,
                                rb_str_new_lit("::"), rb_str_new_lit("."));

  // 7 is the length of "Elixir."
  if (7 + RETF_STR_LEN(elixirized) > 255) {
    rb_raise(rb_eArgError,
             "class name is too long to encode, must be no "
             "greater than 255 characters");
  }

  // 7 is the length of "Elixir."
  size_t len = RSTRING_LEN(elixirized) + 7;

  if (len < 256) {
    unsigned char new_len = len;
    ensure_str_extra_capacity(str_buffer, 2 + len);
    rb_str_cat(str_buffer, "\x77", 1);
    rb_str_cat(str_buffer, (char *)&new_len, 1);
    rb_str_cat(str_buffer, "Elixir.", 7);
    return rb_str_concat(str_buffer, elixirized);
  } else {
    ensure_str_extra_capacity(str_buffer, 3 + len);
    rb_str_cat(str_buffer, "\x76", 1);

    uint16_t nlen = htobe16(len);

    rb_str_cat(str_buffer, (char *)&nlen, 2);
    rb_str_cat(str_buffer, "Elixir.", 7);
    return rb_str_concat(str_buffer, elixirized);
  }
}
