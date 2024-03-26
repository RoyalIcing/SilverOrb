defmodule SilverOrb.Arena do
  @moduledoc """
  Arena allocation.

  See https://www.rfleury.com/p/untangling-lifetimes-the-arena-allocator

  ```elixir
  defmodule ArenaExample do
    SilverOrb.Arena.def(First, pages: 2)
    SilverOrb.Arena.def(Second, pages: 4, max_pages: 10)

    defw example(), a: I32.UnsafePointer, b: I32.UnsafePointer do
      a = First.alloc(4)
      Memory.store!(I32, a, 42)

      b = Second.alloc(4)
      Memory.store!(I32, b, 99)

      assert!(a !== First.alloc(4))
      First.rewind()
      assert!(a === First.alloc(4))
    end
  end
  ```
  """

  use Orb

  alias Orb.Instruction

  @doc false
  def alloc_impl(values_mod, byte_count) do
    offset_global_name = values_mod.offset_global_name()
    max_end_page_offset = values_mod.max_end_page_offset()

    Orb.snippet Orb.U32, new_ptr: I32.UnsafePointer do
      new_ptr = Instruction.global_get(Orb.I32, offset_global_name)

      # TODO: we need an option for alignment.
      if new_ptr + byte_count > max_end_page_offset * Memory.page_byte_size() do
        unreachable!()
      end

      if new_ptr + byte_count > Memory.size() * Memory.page_byte_size() do
        _ = Memory.grow!(1)
      end

      Instruction.global_set(Orb.I32, offset_global_name, new_ptr + byte_count)

      new_ptr
    end
  end

  @doc false
  def rewind_impl(values_mod) do
    offset_global_name = values_mod.offset_global_name()
    start_page_offset = values_mod.start_page_offset()

    Orb.snippet Orb.S32 do
      Instruction.global_set(
        Orb.I32,
        offset_global_name,
        start_page_offset * Orb.Memory.page_byte_size()
      )
    end
  end

  @doc false
  defw string_equal_impl(lhs: I32.UnsafePointer, rhs: I32.UnsafePointer), I32,
  i: I32,
  byte_a: I32,
  byte_b: I32 do
    loop EachByte, result: I32 do
      byte_a = Memory.load!(I32.U8, I32.add(lhs, i))
      byte_b = Memory.load!(I32.U8, I32.add(rhs, i))

      if I32.eqz(byte_a) do
        return(I32.eqz(byte_b))
      end

      if I32.eq(byte_a, byte_b) do
        i = I32.add(i, 1)
        EachByte.continue()
      end

      return(0x0)
    end
  end

  def inline_string_match(value, result_type, do: cases) do
    statements =
      for {:->, _, [input, target]} <- cases do
        case input do
          # _ ->
          # catchall, like an else clause
          [{:_, _, _}] ->
            quote do
              Orb.InstructionSequence.new(unquote(Orb.__get_block_items(target)))
            end

          [match] ->
            quote do
              Orb.IfElse.new(
                nil,
                unquote(__MODULE__).string_equal_impl(unquote(value), unquote(match)),
                Orb.InstructionSequence.new([
                  Orb.InstructionSequence.new(unquote(Orb.__get_block_items(target))),
                  Orb.Control.break(:arena_string_match)
                ]),
                nil
              )
            end
        end
      end

    has_catchall? = Enum.any?(cases, &match?({:->, _, [[{:_, _, _}], _]}, &1))

    final_instruction =
      case has_catchall? do
        false -> quote do: %Orb.Unreachable{}
        true -> quote do: Orb.InstructionSequence.empty()
      end

    quote do
      Orb.Control.block :arena_string_match, unquote(result_type) do
        Orb.InstructionSequence.new(unquote(statements))
        unquote(final_instruction)
      end
    end
  end

  @doc """
  Match strings to content of passed `arena_mod`.
  """
  defmacro match_string(arena_mod, result_type, do: cases) do
    SilverOrb.Arena.inline_string_match(quote(do: unquote(arena_mod).Values.start_byte_offset()), result_type, do: cases)
  end

  @doc """
  Defines an arena of memory. An Elixir module with your passed `name` is defined with `alloc!/1` and `rewind/0` functions.

  ## Options

  When defining an arena, two options can be given:

  - `:pages` — The number of pages to allocate for this arena. The global memory is increased by this count.
  - `:max_pages` — The maxmimum number of pages this can increase the global memory by using `Orb.Memory.grow!/1`. Only the last arena can support `max_pages`, as otherwise multiple arenas each growing in size will end up overlapping.
  """
  defmacro def(name, opts) do
    quote do
      require Orb.Memory

      module_name = Module.concat(__MODULE__, unquote(name))
      page_count = unquote(opts[:pages])
      max_page_count = unquote(opts[:max_pages])
      page_offset = Orb.Memory.pages(page_count)
      end_page_offset = page_offset + page_count
      max_end_page_offset = page_offset + (max_page_count || page_count)
      page_byte_size = Orb.Memory.page_byte_size()
      # TODO: this needs to incorporate whether memory has been grown.
      valid_memory_range =
        Range.new(page_offset * page_byte_size, end_page_offset * page_byte_size)

      offset_global_name =
        String.to_atom("#{Macro.inspect_atom(:literal, module_name)}.bump_offset")

      Module.create(
        Module.concat([module_name, Values]),
        quote do
          def start_page_offset(), do: unquote(page_offset)
          def end_page_offset(), do: unquote(page_offset + page_count)
          def max_end_page_offset(), do: unquote(page_offset + (max_page_count || page_count))
          def max_page_count(), do: unquote(max_page_count)
          def start_byte_offset(), do: start_page_offset() * Orb.Memory.page_byte_size()
          def offset_global_name(), do: unquote(offset_global_name)
        end,
        unquote(Macro.Env.location(__CALLER__))
      )

      Module.create(
        Module.concat([module_name, UnsafePointer]),
        quote do
          def wasm_type(), do: :i32
          def memory_range(), do: unquote(valid_memory_range |> Macro.escape())

          def validate!(ptr) do
            with do
              %{first: first, last: last} = memory_range()
              Orb.DSL.assert!(I32.band(I32.ge_u(ptr, first), I32.le_u(ptr, last)))
            end
          end
        end,
        unquote(Macro.Env.location(__CALLER__))
      )

      Module.create(
        # Rename StringSlice?
        Module.concat([module_name, String]),
        quote do
          def wasm_type(), do: :i64
        end,
        unquote(Macro.Env.location(__CALLER__))
      )

      global(
        do: [
          {offset_global_name, page_offset * Orb.Memory.page_byte_size()}
        ]
      )

      with do
        defmodule unquote(name) do
          use Orb

          alias __MODULE__.Values

          Orb.set_func_prefix(inspect(__MODULE__))

          @doc """
          Allocates memory into this arena. Traps if there is not enough free space.

          See also: https://man7.org/linux/man-pages/man3/alloca.3.html
          """
          defw alloc!(byte_count: I32), I32.UnsafePointer, new_ptr: I32.UnsafePointer do
            SilverOrb.Arena.alloc_impl(Values, Instruction.local_get(I32, :byte_count))
          end

          @doc """
          Rewinds this arena back to the beginning, effectively “freeing” everything that was previously allocated.

          Note: The memory is not zeroed out.
          """
          defw rewind() do
            SilverOrb.Arena.rewind_impl(Values)
          end

          @doc """
          Compares a string to the byte-contents of the arena. Returns `i32` `1` if equal, `0` if not.
          """
          defw string_equal?(str: I32.UnsafePointer), I32 do
            SilverOrb.Arena.string_equal_impl(Values.start_byte_offset(), Instruction.local_get(I32, :str))
          end
        end
      end

      Orb.include(unquote(__MODULE__))
      Orb.include(__MODULE__.unquote(name))
      alias __MODULE__.{unquote(name)}

      # require module_name, as: unquote(name)
    end
  end
end
