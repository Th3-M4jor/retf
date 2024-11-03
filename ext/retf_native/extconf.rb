# frozen_string_literal: true

require 'mkmf'

# required for converting network byte order
# to host byte order and vice versa
abort('endian.h is required') unless have_header('endian.h')

have_func('rb_str_strlen') # truffleruby
have_func('rb_mod_name') # truffleruby
have_func('rb_big_eq') # truffleruby
have_func('rb_big_and') # truffleruby
have_func('rb_big_rshift') # truffleruby
have_func('rb_big_unpack') # truffleruby

append_cflags('-flto')
create_makefile('retf_native')
