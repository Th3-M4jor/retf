# frozen_string_literal: true

require 'mkmf'

# required for converting network byte order
# to host byte order and vice versa
abort('endian.h is required') unless have_header('endian.h')

create_makefile('retf_native')
