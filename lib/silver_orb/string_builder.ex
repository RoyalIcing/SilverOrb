defmodule SilverOrb.StringBuilder do
  @moduledoc """
  Build strings with dynamic content.

  ```elixir
  defmodule MultiStepForm do
    use Orb
    use SilverOrb.BumpAllocator
    use SilverOrb.StringBuilder

    global do
      @step 1
    end

    global :export_mutable do
      @step_count 4
    end

    defw(get_current_step(), I32, do: @step)

    defwp change_step(step: I32) do
      @step =
        if step < 1 do
          1
        else
          if(step > @step_count, do: @step_count, else: step)
        end
    end

    defw(next_step(), do: change_step(@step + 1))
    defw(previous_step(), do: change_step(@step - 1))
    defw(jump_to_step(step: I32), do: change_step(step))

    defw(to_string(), StringBuilder, do: to_html())

    defw to_html(), StringBuilder do
      build! do
        build_step(1)
        build_step(2)
        build_step(3)
        build_step(4)
        build_step(5)
      end
    end

    defwp build_step(step: I32), StringBuilder, current_step?: I32 do
      current_step? = step === Orb.Instruction.global_get(:i32, :step)

      build! do
        ~S[<div class="w-4 h-4 text-center ]

        if current_step? do
          ~S[bg-blue-600 text-white]
        else
          ~S[text-black]
        end

        ~S[">]
        append!(decimal_u32: step)
        ~S[</div>\\n]
      end
    end
  end
  ```
  """

  use Orb
  use SilverOrb.BumpAllocator
  use SilverOrb.Mem

  @behaviour Orb.CustomType
  @impl Orb.CustomType
  def wasm_type(), do: :i32
  @impl Orb.CustomType
  def byte_count(), do: 1

  defmodule Format do
    @moduledoc false
    use Orb.Import

    defw(f32(value: F32, str_ptr: I32.U8.UnsafePointer), I32)
  end

  I32.global(bump_write_level: 0)

  defmacro __using__(_) do
    quote do
      use SilverOrb.Mem
      use I32.String
      use SilverOrb.IntFormatter

      Orb.include(unquote(__MODULE__))
      import unquote(__MODULE__)

      alias SilverOrb.StringBuilder

      # global do
      #   @bump_write_level 0
      # end

      I32.global(bump_write_level: 0)
    end
  end

  defwp bump_write_start() do
    if I32.eqz(@bump_write_level) do
      @bump_mark = @bump_offset
    end

    @bump_write_level = @bump_write_level + 1
  end

  defwp bump_write_done(), __MODULE__ do
    assert!(@bump_write_level > 0)
    @bump_write_level = @bump_write_level - 1

    if I32.eqz(@bump_write_level) do
      # I32.store8(@bump_offset, 0x0)
      # Memory.store!(I32.U8, @bump_offset, 0x0)
      Memory.store!(I32.U8, @bump_offset, 0x0)
      # {:i32, :store8, @bump_offset, 0x0}
      @bump_offset = I32.add(@bump_offset, 1)
    end

    @bump_mark
  end

  defwp bump_write_str(str_ptr: I32.U8.UnsafePointer), len: I32 do
    return(if: I32.eq(str_ptr, @bump_mark))

    len = typed_call(I32, :strlen, [str_ptr])
    SilverOrb.Mem.memcpy(@bump_offset, str_ptr, len)
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
      List.wrap(
        case block do
          {:__block__, _, items} -> items
          term -> term
        end
      )

    for item <- items do
      quote do
        with do
          # import Kernel, except: [if: 2]
          # import Kernel, except: [@: 1]
          # import Kernel
          import Orb.IfElse.DSL, only: []
          import unquote(__MODULE__).DSL

          unquote(__MODULE__).build_item(unquote(item))
        end
      end
    end
  end

  def build_item(string) when is_binary(string) do
    append!(string: string)
  end

  def build_item(%Orb.Constants.NulTerminatedString{string: ""}) do
    # FIXME
    :nop
  end

  def build_item(%Orb.Constants.NulTerminatedString{} = term) do
    append!(string: term)
  end

  def build_item(%{push_type: __MODULE__} = str_ptr) do
    append!(string: str_ptr)
  end

  def build_item(%{push_type: Orb.Constants.NulTerminatedString} = str_ptr) do
    append!(string: str_ptr)
  end

  # TODO: String64
  def build_item(%{push_type: Orb.I32.String} = str_ptr) do
    append!(string: str_ptr)
  end

  def build_item(%struct{push_type: type} = instruction)
      when struct in [Orb.Instruction, Orb.VariableReference] and type in [:f32, Orb.F32, F32] do
    append!(decimal_f32: instruction)
  end

  def build_item(term), do: term

  # For nested build functions.
  # We want inner functions to also return strings for easier debugging of their result, not just append.
  def append!(function, a, b, c) when is_atom(function) do
    import Orb.DSL

    typed_call(I32, function, [a, b, c]) |> Orb.Stack.drop()
  end

  def append!(function, a, b) when is_atom(function) do
    import Orb.DSL

    typed_call(I32, function, [a, b]) |> Orb.Stack.drop()
  end

  def append!(function, args) when is_atom(function) and is_list(args) do
    import Orb.DSL

    typed_call(I32, function, args) |> Orb.Stack.drop()
  end

  def append!(function, a) when is_atom(function) do
    import Orb.DSL

    typed_call(I32, function, [a]) |> Orb.Stack.drop()
  end

  def append!(function) when is_atom(function) do
    import Orb.DSL

    typed_call(I32, function, []) |> Orb.Stack.drop()
  end

  def append!(constant) when is_binary(constant) do
    bump_write_str(constant)
  end

  def append!(%Orb.Constants.NulTerminatedString{string: ""}) do
    :nop
  end

  def append!(%Orb.Constants.NulTerminatedString{} = str_ptr) do
    bump_write_str(str_ptr)
  end

  def append!(string: str_ptr) do
    bump_write_str(str_ptr)
  end

  def append!(u8: char) do
    snippet U32 do
      Memory.store!(I32.U8, @bump_offset, char)
      # {:i32, :store8, @bump_offset, char}
      @bump_offset = @bump_offset + 1
    end
  end

  def append!(ascii: char), do: append!(u8: char)

  def append!(decimal_u32: int) do
    snippet do
      @bump_offset = SilverOrb.IntFormatter.format_u32(int, @bump_offset)
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

    snippet U32 do
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
        initial + I32.when?(following <= 9, do: ?0, else: ?A - 10)
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
