<h1 align="center">🕸️🔋 SilverOrb: the standard library for <a href="https://github.com/RoyalIcing/Orb">Orb</a></h1>

<p dir="ltr" align="center"><a href="https://hexdocs.pm/silver_orb" rel="nofollow">Docs</a></p>

WebAssembly is low level — you essentially get to define global variables, an array of memory, and some functions to operate on them. It’s not batteries-included.

SilverOrb provides these batteries so common tasks are easier. They are:

- [`StringBuilder`](https://hexdocs.pm/silver_orb/SilverOrb.StringBuilder.html) for assembling strings from dynamic parts.
- `IntFormatter` for converting integers to strings.
- `Arena` allocator for memory management.
- `ASCII` (coming soon) for operating on ASCII strings.
- `UTF8` (coming soon) for operating on UTF-8 strings.
- `IntParser` (coming soon) for converting strings to integers.
- `XMLBuilder` (coming soon) for assembling XML from dynamic parts.
- `FormData` (coming soon) for decoding/encoding `application/x-www-form-urlencoded` strings.
- `URLSearchParams` (coming soon) for decoding/encoding URL query strings.
- `URL` (coming soon) for decoding/encoding URLs.
- `Request` (later) for encoding HTTP/1 requests.
- `Response` (later) for encoding HTTP/1 responses.
- `Iterator` (coming soon) for creating a custom sequence type that can be iterated through.

## Installation

The package can be installed by adding `silver_orb` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:silver_orb, "~> 0.0.10"}
  ]
end
```

## Inspiration

- https://www.rfleury.com/p/untangling-lifetimes-the-arena-allocator
