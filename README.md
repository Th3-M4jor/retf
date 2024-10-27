# RETF
A ~~pure Ruby~~ parser and serializer for the Erlang External Term Format (ETF).

(This started as a pure Ruby implementation but it was slow as molasses compared to JSON and msgpack, so it was rewritten in C)

## Installation
```bash
gem install retf
```

## Usage
```ruby
require 'retf'

# Serialize a primitive value
Retf.encode(42) # => "\x83a*"

# Deserialize a primitive value
Retf.decode("\x83F@\x8C\xC8\x00\x00\x00\x00\x00") # => 921.0

# Serialize a more complex value
Retf.encode([:foo, 42, {bar: 3.14}])
# => "\x83l\x00\x00\x00\x03w\x03fooa*t\x00\x00\x00\x01w\x03barF@\t\x1E\xB8Q\xEB\x85\x1Fj"
```

## Type Mapping
Most Erlang types are supported
and mapped to their Ruby equivalents
unless otherwise noted below.

- Most Atoms are converted to symbols with a few exceptions noted below
- PIDs are converted into a `Retf::PID` Class
- References are converted into a `Retf::Reference` Class
- Tuples are converted into `Retf::Tuple` Class
- Ports, and Functions are not supported and will raise an error if encountered
- Charlists are parsed as Ruby strings

### Atoms
The following atoms are special cased: `nil`, `true`, and `false`.

Another exception is that atoms which look like an Elixir module name are "rubified"
and an attempt is made to convert them to a constant. For example, an atom named 
`:"Elixir.MyModule.SubModule"` would be converted to `MyModule::SubModule` and
if that constant does not exist, the symbol `:"Elixir.MyModule.SubModule"` will be returned.


### Custom Types
If a class implements the `#as_etf` method it will be called
when serializing an instance of that class. The method should
return a `Hash` containing its state, which will be serialized
as a map with an extra `:__struct__` key containing the class name
converted into an "Elixir"ized format (e.g. `MyModule::MyClass` -> `:"Elixir.MyClass.MyModule"`).

When deserializing, if a map has a `:__struct__` key, an attempt will be made to
locate a class with the given name after "Rubifying" it
(e.g. `:"Elixir.MyClass.MyModule"` -> `MyModule::MyClass`)
and call its `.from_etf` method with the map passed as an argument.
If the class does not exist or does not respond to `.from_etf`
then the map will be unmodified.
