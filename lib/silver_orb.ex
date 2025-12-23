defmodule SilverOrb do
  @moduledoc """
  WebAssembly is low level — you essentially get to define global variables, an array of memory, and some functions to operate on them. It’s not batteries-included.

  `SilverOrb` provides several extra batteries so common tasks are easier. They are:

  - `SilverOrb.Arena` allocator for memory management.
  - `SilverOrb.ASCII` for operating on ASCII strings.
  - `SilverOrb.UTF8` for operating on UTF-8 strings.
  - `SilverOrb.IntFormatter` for converting integers to strings.
  - `SilverOrb.IntParser` (coming soon) for converting strings to integers.
  - `SilverOrb.StringBuilder` for assembling strings from dynamic parts.
  - `SilverOrb.XMLBuilder` for assembling XML from dynamic parts.
  - `SilverOrb.URI` for decoding/encoding URIs/URLs.
  - `SilverOrb.URLSearchParams` (coming soon) for decoding/encoding URL query strings.
  - `SilverOrb.FormData` (coming soon) for decoding/encoding `application/x-www-form-urlencoded` strings.
  - `SilverOrb.Request` (coming soon) for encoding HTTP/1 requests.
  - `SilverOrb.Response` (coming soon) for encoding HTTP/1 responses.
  - `SilverOrb.Iterator` (coming soon) for creating a custom sequence type that can be iterated through.
  """

  defmacro __using__(_opts) do
    quote do
      use Orb

      require SilverOrb
    end
  end

  # defmacro defarena do

  # end
end
