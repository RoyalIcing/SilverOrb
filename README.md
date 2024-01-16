# SilverOrb

A standard library for Orb.

The docs can be found at <https://hexdocs.pm/silver_orb>.

WebAssembly is low level — you essentially get to define global variables, an array of memory, and some functions to operate on them. It’s not batteries-included.

SilverOrb provides a few extra batteries so common tasks are easier. They are:

- `Arena` allocator for memory management.
- `ASCII` for operating on ASCII strings.
- `UTF8` for operating on UTF-8 strings.
- `IntFormatter` for converting integers to strings.
- `IntParser` for converting strings to integers.
- `StringBuilder` for assembling strings from dynamic parts.
- `XMLBuilder` for assembling XML from dynamic parts.
- `FormData` for decoding/encoding `application/x-www-form-urlencoded` strings.
- `URLSearchParams` for decoding/encoding URL query strings.
- `URL` for decoding/encoding URLs.
- `Request` for encoding HTTP/1 requests.
- `Response` for encoding HTTP/1 responses.
- `Iterator` for creating a custom sequence type that can be iterated through.

## Installation

The package can be installed by adding `silver_orb` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:silver_orb, "~> 0.0.5"}
  ]
end
```

## Inspiration

- https://www.rfleury.com/p/untangling-lifetimes-the-arena-allocator
