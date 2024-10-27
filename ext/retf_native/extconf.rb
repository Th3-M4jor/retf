# frozen_string_literal: true

require 'mkmf'

# required for converting network byte order
# to host byte order and vice versa
abort('endian.h is required') unless have_header('endian.h')
abort('rb_str_strlen is required') unless have_func('rb_str_strlen')

append_cflags('-flto')
create_makefile('retf_native')
