defmodule SilverOrb.URI do
  alias ElixirLS.LanguageServer.Providers.Completion.Reducers.Bitstring
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

  defp flag(:scheme), do: 0b1
  defp flag(:authority), do: 0b10
  defp flag(:userinfo), do: 0b100
  defp flag(:host), do: 0b1000
  defp flag(:port), do: 0b1_0000
  defp flag(:path), do: 0b10_0000
  defp flag(:query), do: 0b100_0000
  defp flag(:fragment), do: 0b1000_0000

  def parse_flags(flags) do
    import Bitwise

    flags
    |> Enum.reduce(0, fn flag, acc ->
      acc ||| flag(flag)
    end)
  end

  defw parse(input: Str), URIParseResult,
    state: I32,
    i: I32,
    char: I32.U8,
    flags: I32,
    scheme_i: I32,
    scheme_size: I32,
    authority_i: I32,
    userinfo_i: I32,
    userinfo_size: I32,
    host_i: I32,
    host_size: I32,
    port_i: I32,
    port_size: I32,
    path_i: I32,
    path_size: I32,
    query_i: I32,
    query_size: I32,
    fragment_i: I32,
    fragment_size: I32 do
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

    state = const(:initial)

    loop EachChar do
      char = Memory.load!(I32.U8, input[:ptr] + i)
      # Log.u32(char)
      # Log.u32(char === ?:)
      # Log.putc(char)

      Control.block State do
        if state === const(:initial) &&& char === ?: do
          flags = flags ||| flag(:scheme)
          scheme_i = 0
          scheme_size = i
          state = const(:hier_part)
          State.break()
        end

        if state === const(:hier_part) do
          if char === ?/ &&& i + 1 < input[:size] do
            char = Memory.load!(I32.U8, input[:ptr] + i + 1)

            if char === ?/ do
              i = i + 1
              state = const(:authority_start)
              State.break()
            end
          end

          flags = flags ||| flag(:path)
          state = const(:path)
          path_i = i

          State.break()
        end

        if state === const(:authority_start) do
          if char === ?/ do
            flags = flags ||| flag(:path)
            state = const(:path)
            path_i = i
          else
            state = const(:authority)
            authority_i = i
          end

          State.break()
        end

        if state === const(:authority) do
          if host_i do
            flags = flags ||| flag(:host)
          end

          # Log.puts("authority state")
          # Log.putc(char)
          # Log.putc(0x20)
          # Log.u32(char)

          cond result: nil do
            char === ?@ ->
              userinfo_i = authority_i
              userinfo_size = i - authority_i
              authority_i = i + 1
              flags = flags ||| flag(:userinfo)

            # state = const(:host)

            char === ?: ->
              host_i = authority_i
              host_size = i - authority_i
              port_i = i + 1

              flags =
                flags ||| flag(:port) |||
                  if(host_size, result: I32, do: i32(flag(:host)), else: i32(0))

              state = const(:port)

            char === ?/ or char === ?? ->
              if char === ?/ do
                path_i = i
                flags = flags ||| flag(:path)
                state = const(:path)
              end

              if char === ?? do
                query_i = i
                flags = flags ||| flag(:query)
                state = const(:query)
              end

              if userinfo_i === 0 do
                host_i = authority_i
                host_size = i - authority_i
                flags = flags ||| flag(:host)
              end

              if port_i do
                port_size = i - port_i
              end

            true ->
              Orb.InstructionSequence.empty()
          end

          State.break()
        end

        # if state === const(:host) &&& char === ?: do
        #   flags = flags ||| flag(:port)
        #   state = const(:port)
        #   State.break()
        # end

        if state === const(:port) &&& char === ?/ do
          if port_i do
            port_size = i - port_i
          end

          path_i = i
          flags = flags ||| flag(:path)
          state = const(:path)
          State.break()
        end

        if state === const(:path) &&& char === ?? do
          path_size = i - path_i
          query_i = i + 1
          flags = flags ||| flag(:query)
          state = const(:query)
          State.break()
        end

        if state === const(:path) &&& char === ?# do
          path_size = i - path_i
          fragment_i = i + 1
          flags = flags ||| flag(:fragment)
          state = const(:fragment)
          State.break()
        end

        if state === const(:query) &&& char === ?# do
          query_size = i - query_i
          fragment_i = i + 1
          flags = flags ||| flag(:fragment)
          state = const(:fragment)
          State.break()
        end
      end

      i = i + 1

      if i < input[:size] do
        EachChar.continue()
      end
    end

    # Log.u32(state)
    # Log.u32(const(:path))
    # Log.u32(path_i)

    if state === const(:authority) do
      flags = flags ||| flag(:host)
      host_i = authority_i
      host_size = i - authority_i
    end

    if state === const(:path) do
      path_size = i - path_i
    end

    if state === const(:query) do
      query_size = i - query_i
    end

    if state === const(:fragment) do
      fragment_size = i - fragment_i
    end

    {
      flags,
      input[:ptr] + scheme_i,
      scheme_size,
      input[:ptr] + userinfo_i,
      userinfo_size,
      input[:ptr] + host_i,
      host_size,
      input[:ptr] + port_i,
      port_size,
      input[:ptr] + path_i,
      path_size,
      input[:ptr] + query_i,
      query_size,
      input[:ptr] + fragment_i,
      fragment_size
    }
  end
end
