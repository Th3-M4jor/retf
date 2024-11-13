# frozen_string_literal: true

require 'mkmf'

# required for converting network byte order
# to host byte order and vice versa
abort('endian.h is required') unless have_header('endian.h')

have_func('rb_str_strlen', 'ruby.h') # truffleruby
have_func('rb_mod_name', 'ruby.h') # truffleruby
have_func('rb_big_eq', 'ruby.h') # truffleruby
have_func('rb_big_and', 'ruby.h') # truffleruby
have_func('rb_big_rshift', 'ruby.h') # truffleruby
have_func('rb_big_unpack', 'ruby.h') # truffleruby
have_func('rb_hash_bulk_insert', 'ruby.h') # TruffleRuby

append_cflags('-flto')
create_makefile('retf_native')
