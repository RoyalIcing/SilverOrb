defmodule SilverOrb.Arena do
  # See https://www.rfleury.com/p/untangling-lifetimes-the-arena-allocator

  use Orb

  alias Orb.Instruction

  def alloc_impl(values_mod, byte_count) do
    offset_global_name = values_mod.offset_global_name()
    end_page_offset = values_mod.end_page_offset()
    max_end_page_offset = values_mod.max_end_page_offset()
    max_page_count = values_mod.max_page_count()

    case max_page_count do
      nil ->
        Orb.snippet Orb.S32, new_ptr: I32.UnsafePointer do
          new_ptr = Instruction.global_get(Orb.I32, offset_global_name)

          if new_ptr + byte_count > end_page_offset * Orb.Memory.page_byte_size() do
            unreachable!()
          end

          Instruction.global_set(Orb.I32, offset_global_name, new_ptr + byte_count)

          new_ptr
        end

      max_page_count when is_integer(max_page_count) ->
        Orb.snippet Orb.S32, new_ptr: I32.UnsafePointer do
          new_ptr = Instruction.global_get(Orb.I32, offset_global_name)

          if new_ptr + byte_count > max_end_page_offset * Memory.page_byte_size() do
            # _ = Memory.grow!(1)
            unreachable!()
          end

          if new_ptr + byte_count > Memory.size() * Memory.page_byte_size() do
            _ = Memory.grow!(1)
          end

          Instruction.global_set(Orb.I32, offset_global_name, new_ptr + byte_count)

          new_ptr
        end
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

          # https://man7.org/linux/man-pages/man3/alloca.3.html
          defw alloc(byte_count: I32), I32.UnsafePointer, new_ptr: I32.UnsafePointer do
            SilverOrb.Arena.alloc_impl(Values, Instruction.local_get(I32, :byte_count))
          end

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
