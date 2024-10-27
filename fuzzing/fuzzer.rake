# frozen_string_literal: true

desc 'Fuzzing task for the decoder'
task fuzz: :compile do
  require 'retf'
  require 'securerandom'

  # Generates random data and ensures that it either decodes successfully or raises an error
  # The thing we don't want is for the program to crash

  puts 'Beginning fuzzing...'

  1000.times do
    data = SecureRandom.random_bytes(rand(1..1000))

    encoded = [131, data].pack('Ca*')

    Retf.decode(encoded)
  rescue StandardError, NoMemoryError
    next
  end

  puts 'Fuzzing complete!'
end
