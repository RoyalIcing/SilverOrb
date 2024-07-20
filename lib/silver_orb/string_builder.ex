defmodule SilverOrb.StringBuilder do
  @moduledoc """
  Build strings with dynamic content.

  Here’s an example with components rendering dynamic HTML:

  ```elixir
  defmodule HelloWorldComponent do
    use Orb
    use SilverOrb.StringBuilder

    defwp daytime?(hour: I32), I32 do
      hour >= 6 &&& hour <= 19
    end

    defw render(hour: I32), StringBuilder do
      StringBuilder.build! do
        "<h1>"

        if daytime?(hour) do
          "Hello 🌞 sunny world"
        else
          "Hello 🌛 moonlit world"
        end

        "</h1>\\n"
      end
    end
  end

  defmodule DynamicHTMLPage do
    use Orb
    use SilverOrb.StringBuilder

    Orb.include(HelloWorldComponent)

    global do
      @hour_of_day 8
    end

    defw set_hour_of_day(hour: I32) do
      @hour_of_day = hour
    end

    defw text_html(), StringBuilder do
      StringBuilder.build! do
        \"\"\"
        <!doctype html>
        <meta charset="utf-8">
        \"\"\"

        HelloWorldComponent.render(@hour_of_day)
      end
    end
  end
  ```
  """

  use Orb
  # use SilverOrb.BumpAllocator
  # use SilverOrb.Mem

  @behaviour Orb.CustomType
  @impl Orb.CustomType
  def wasm_type(), do: {:i32, :i32}

  defmodule Format do
    @moduledoc false
    use Orb.Import, name: :format

    defw(f32(value: F32, str_ptr: I32.U8.UnsafePointer), I32)
  end

  # I32.global(bump_offset: 0, bump_mark: 0, bump_write_level: 0)

  defmodule Constants do
    def init_offset() do
      1 * Memory.page_byte_size()
    end
  end

  Memory.pages(2)

  I32.global(
    bump_offset: Constants.init_offset(),
    bump_mark: 0,
    bump_write_level: 0
  )

  defmacro __using__(_) do
    quote do
      # use SilverOrb.Mem
      use SilverOrb.IntFormatter

      Orb.include(unquote(__MODULE__))

      require alias unquote(__MODULE__)
      import unquote(__MODULE__)

      # global do
      #   @bump_write_level 0
      # end

      Memory.pages(2)

      I32.global(
        bump_offset: Constants.init_offset(),
        bump_mark: 0,
        bump_write_level: 0
      )
    end
  end

  defwp bump_write_start() do
    if I32.eqz(@bump_write_level) do
      # TODO: refactor based on Arena instead?
      @bump_offset = Constants.init_offset()
      @bump_mark = @bump_offset
    end

    @bump_write_level = @bump_write_level + 1
  end

  defwp bump_write_done(), __MODULE__ do
    assert!(@bump_write_level > 0)
    @bump_write_level = @bump_write_level - 1

    {@bump_mark, @bump_offset - @bump_mark}
  end

  defwp bump_write_str(str_ptr: I32.UnsafePointer, len: I32),
    i: I32,
    char: I32 do
    return(if: I32.eq(str_ptr, @bump_mark) ||| I32.eqz(len))

    loop EachChar do
      char = Memory.load!(I32.U8, str_ptr + i)

      Memory.store!(I32.U8, @bump_offset + i, char)

      if i < len do
        i = i + 1
        EachChar.continue()
      end

      # EachChar.continue()
      # |> if i < len do
      #   i = i + 1
      # end
    end

    # Memory.store!(I32.U8, @bump_offset + len - 1, ?q)

    @bump_offset = @bump_offset + len
  end

  defwp bump_written?(), I32 do
    @bump_offset > @bump_mark
  end

  def build_begin!(), do: bump_write_start()
  def build_done!(), do: bump_write_done()
  def appended?(), do: bump_written?()

  defmacro build!(do: block) do
    items = __build_block(block)

    quote do
      Orb.InstructionSequence.new(unquote(__MODULE__), [
        build_begin!(),
        Orb.InstructionSequence.new(nil, unquote(items)),
        build_done!()
      ])
    end
  end

  def __build_block(block) do
    items =
      block
      |> case do
        {:__block__, _, items} -> items
        term -> term
      end
      |> List.wrap()

    for item <- items do
      quote do
        with do
          import Orb.IfElse.DSL, only: []
          import unquote(__MODULE__).DSL

          unquote(__MODULE__).build_item(unquote(item))
        end
      end
    end
  end

  def build_item("") do
    Orb.InstructionSequence.empty()
  end

  def build_item(string) when is_binary(string) do
    append!(string: string)
  end

  def build_item(%Orb.Str{string: ""}) do
    Orb.InstructionSequence.empty()
  end

  def build_item(%Orb.Str{} = term) do
    append!(string: term |> dbg())
  end

  def build_item(%{push_type: __MODULE__} = string_builder_call) do
    # Orb.Stack.drop(string_builder_call)
    %Orb.Stack.Drop{
      instruction: string_builder_call,
      count: 2
    }
  end

  # TODO: String64
  def build_item(%{push_type: Orb.Str} = str_ptr) do
    append!(string: str_ptr)
  end

  def build_item(%struct{push_type: type} = instruction)
      when struct in [Orb.Instruction, Orb.VariableReference] and type in [:f32, Orb.F32] do
    append!(decimal_f32: instruction)
  end

  def build_item(term), do: term

  # For nested build functions.
  # We want inner functions to also return strings for easier debugging of their result, not just append.
  def append!(function, a, b, c) when is_atom(function) do
    import Orb.DSL

    Orb.Instruction.typed_call(I32, [], function, [a, b, c]) |> Orb.Stack.drop()
  end

  def append!(function, a, b) when is_atom(function) do
    import Orb.DSL

    Orb.Instruction.typed_call(I32, [], function, [a, b]) |> Orb.Stack.drop()
  end

  def append!(function, args) when is_atom(function) and is_list(args) do
    import Orb.DSL

    Orb.Instruction.typed_call(I32, [], function, args) |> Orb.Stack.drop()
  end

  def append!(function, a) when is_atom(function) do
    import Orb.DSL

    Orb.Instruction.typed_call(I32, [], function, [a]) |> Orb.Stack.drop()
  end

  def append!(function) when is_atom(function) do
    import Orb.DSL

    Orb.Instruction.typed_call(I32, [], function, []) |> Orb.Stack.drop()
  end

  def append!(constant) when is_binary(constant) do
    _ = &bump_write_str/2

    Orb.InstructionSequence.new(nil, [
      constant,
      Orb.Instruction.typed_call(
        nil,
        [I32.UnsafePointer, I32],
        :bump_write_str,
        []
      )
    ])

    # bump_write_str(constant)
  end

  def append!(%Orb.Str{string: ""}) do
    Orb.InstructionSequence.empty()
  end

  def append!(%Orb.Str{} = str) do
    Orb.InstructionSequence.new(nil, [
      str,
      Orb.Instruction.typed_call(
        nil,
        [:i32, :i32],
        :bump_write_str,
        []
      )
    ])

    # bump_write_str(str)
  end

  def append!(string: str) do
    Orb.InstructionSequence.new(nil, [
      str,
      Orb.Instruction.typed_call(
        nil,
        [:i32, :i32],
        :bump_write_str,
        []
      )
    ])

    # bump_write_str(str)
  end

  def append!(u8: char) do
    Orb.snippet U32 do
      Memory.store!(I32.U8, @bump_offset, char)
      # {:i32, :store8, @bump_offset, char}
      @bump_offset = @bump_offset + 1
    end
  end

  def append!(ascii: char), do: append!(u8: char)

  def append!(decimal_u32: int) do
    Orb.snippet do
      # Orb.Stack.drop(Orb.I32)
      # mut!(@bump_offset).write

      Orb.InstructionSequence.new(nil, [
        SilverOrb.IntFormatter.decimal_u32(int, @bump_offset),
        # @bump_offset = @bump_offset + Orb.Stack.pop(Orb.I32)
        @bump_offset = Orb.Instruction.i32(:add, @bump_offset),
        # FIXME: should be able to use Orb.Stack.pop/1 here
        Orb.Stack.drop(%Orb.Nop{push_type: Orb.I32})
      ])
    end
  end

  # def append!(decimal_f32: f) do
  #   snippet do
  #     @bump_offset =
  #       Format.f32(f, @bump_offset) + @bump_offset
  #   end
  # end

  def append!(hex_upper: hex) do
    # This might be a bit over the top…
    {initial, following} =
      case hex do
        [_value, {:local_tee, identifier}] ->
          {hex, {:local_get, identifier}}

        _ ->
          {hex, hex}
      end

    Orb.snippet U32 do
      # push(hex)
      #
      # push(I32.le_u(hex, 9))
      #
      # :drop
      #
      # :pop

      # memory32_8![@bump_offset] = I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))

      # I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))

      # push(@bump_offset)
      # push(@bump_offset)

      # memory32_8![0x0] = hex
      # if I32.le_u(memory32_8![0x0].unsigned, 9) do
      #   memory32_8![@bump_offset] = I32.add(memory32_8![0x0].unsigned, ?0)
      # else
      #   memory32_8![@bump_offset] = I32.sub(memory32_8![0x0].unsigned, 10) |> I32.add(?A)
      # end

      # I32.when? I32.le_u(:pop, 9) do
      #   push(hex)
      #   I32.add(:pop, ?0)
      # else
      #   push(hex)
      #   I32.sub(:pop, 10) |> I32.add(?A)
      # end
      # memory32_8![:pop] = :pop

      # memory32_8![@bump_offset] =
      #   initial |> I32.add(I32.when?(I32.le_u(following, 9), do: ?0, else: inline(do: ?A - 10)))

      Memory.store!(
        I32.U8,
        @bump_offset,
        I32.add(initial, if(following <= 9, do: i32(?0), else: i32(?A - 10)))
      )

      # memory32_8![@bump_offset] =
      #   I32.when?(I32.le_u(initial, 9), do: I32.add(following, ?0), else: I32.sub(following, 10) |> I32.add(?A))

      # FIXME: we are evaluating hex multiple times. Do we have to stash it in a variable?
      # memory32_8![@bump_offset] =
      #   I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))

      @bump_offset = @bump_offset + 1
    end
  end

  def append!(list) when is_list(list) do
    for item <- list do
      append!([item])
    end
  end

  #     def append!(list) when is_list(list) do
  #       snippet do
  #         inline for item <- list do
  #           # WE NEED TO INCREMENT bump_offset after each round
  #           case item do
  #             {:ascii, char} ->
  #               snippet do
  #                 memory32_8![@bump_offset] = char
  #               end
  #
  #             {:hex_upper, hex} ->
  #               snippet do
  #                 memory32_8![@bump_offset] =
  #                   I32.when?(I32.le_u(hex, 9), do: I32.add(hex, ?0), else: I32.sub(hex, 10) |> I32.add(?A))
  #               end
  #           end
  #         end
  #
  #         @bump_offset = I32.add(@bump_offset, length(list))
  #       end |> dbg()
  #     end

  # defmacro sigil_E({:<<>>, line, pieces}, []) do
  #   dbg(pieces)

  #   items = __build_block(pieces)

  #   quote do
  #     [
  #       build_begin!(),
  #       unquote(items),
  #       build_done!()
  #     ]
  #   end
  # end

  defmodule DSL do
    alias SilverOrb.StringBuilder

    defmacro if(condition, do: when_true, else: when_false) do
      quote do
        Orb.IfElse.new(
          unquote(condition),
          Orb.InstructionSequence.new(unquote(StringBuilder.__build_block(when_true))),
          Orb.InstructionSequence.new(unquote(StringBuilder.__build_block(when_false)))
        )
      end
    end

    defmacro if(condition, do: when_true) do
      quote do
        Orb.IfElse.new(
          unquote(condition),
          Orb.InstructionSequence.new(unquote(StringBuilder.__build_block(when_true)))
        )
      end
    end
  end
end
