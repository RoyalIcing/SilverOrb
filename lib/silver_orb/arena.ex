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

  def alloc_impl(values_mod, byte_count) do
    offset_global_name = values_mod.offset_global_name()
    max_end_page_offset = values_mod.max_end_page_offset()

    Orb.snippet Orb.S32, new_ptr: I32.UnsafePointer do
      new_ptr = Instruction.global_get(Orb.I32, offset_global_name)

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

      offset_global_name =
        String.to_atom("#{Macro.inspect_atom(:literal, module_name)}.bump_offset")

      Module.create(
        Module.concat([__MODULE__, unquote(name), Values]),
        quote do
          def start_page_offset(), do: unquote(page_offset)
          def end_page_offset(), do: unquote(page_offset + page_count)
          def max_end_page_offset(), do: unquote(page_offset + (max_page_count || page_count))
          def max_page_count(), do: unquote(max_page_count)
          def offset_global_name(), do: unquote(offset_global_name)
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

          set_func_prefix(inspect(__MODULE__))

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
        end
      end

      Orb.include(__MODULE__.unquote(name))
      alias __MODULE__.{unquote(name)}

      # require module_name, as: unquote(name)
    end
  end
end
