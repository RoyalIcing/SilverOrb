defmodule SilverOrb.URI do
  use Orb
  use SilverOrb.Log

  Memory.pages(1)

  defmodule URIParseResult do
    @fields [
      flags: I32,
      scheme: Str,
      userinfo: Str,
      host: Str,
      port: Str,
      path: Str,
      query: Str,
      fragment: Str
    ]

    defstruct @fields
    def fields(), do: @fields

    def from_values([
          flags,
          scheme_ptr,
          scheme_size,
          userinfo_ptr,
          userinfo_size,
          host_ptr,
          host_size,
          port_ptr,
          port_size,
          path_ptr,
          path_size,
          query_ptr,
          query_size,
          fragment_ptr,
          fragment_size
        ]) do
      %__MODULE__{
        flags: flags,
        scheme: {scheme_ptr, scheme_size},
        userinfo: {userinfo_ptr, userinfo_size},
        host: {host_ptr, host_size},
        port: {port_ptr, port_size},
        path: {path_ptr, path_size},
        query: {query_ptr, query_size},
        fragment: {fragment_ptr, fragment_size}
      }
    end

    def from_values(values) do
      struct!(
        __MODULE__,
        Enum.zip_with(fields(), values, fn {key, _type}, value ->
          {key, value}
        end)
      )
    end

    with @behaviour Orb.CustomType do
      @impl Orb.CustomType
      def wasm_type() do
        fields()
        |> Keyword.values()
        |> List.to_tuple()
      end
    end
  end

  defw parse(input: Str), URIParseResult,
    input_slice: Memory.Slice,
    i: I32,
    char: I32.U8,
    flags: I32,
    scheme_ptr: I32.UnsafePointer,
    scheme_size: I32 do
    # URIParseResult.from_values([
    #   0,
    #   {0, 0},
    #   {0, 0},
    #   {0, 0},
    #   {0, 0},
    #   {0, 0},
    #   {0, 0},
    #   {0, 0}
    # ])
    # |> Keyword.values()
    # |> List.to_tuple()

    input_slice = Memory.Slice.from(input[:ptr], input[:size])

    # loop char <- input_slice do
    loop EachChar do
      char = Memory.load!(I32.U8, input[:ptr] + i)
      # Log.u32(char)
      # Log.u32(char === ?:)
      # Log.putc(char)

      if char === ?: do
        flags = flags ||| 0x1
        scheme_ptr = input[:ptr]
        scheme_size = i
      end

      i = i + 1

      if i < input[:size] do
        EachChar.continue()
      end
    end

    {
      flags,
      scheme_ptr,
      scheme_size,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0
    }
  end
end
