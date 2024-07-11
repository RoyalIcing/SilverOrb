defmodule SilverOrb.BumpAllocator do
  @moduledoc """
  A bump allocator for Orb modules.

  ```elixir
  defmodule Example do
    use Orb
    use SilverOrb.BumpAllocator

  end
  ```
  """

  defmodule Constants do
    @bump_start 1 * Orb.Memory.page_byte_size()
    def bump_init_offset(), do: @bump_start
  end

  use Orb

  defmacro __using__(opts \\ []) do
    quote do
      import Orb

      cond do
        Module.has_attribute?(__MODULE__, :wasm_use_bump_allocator) ->
          IO.inspect(unquote(opts), label: "Repeated: use BumpAllocator")

        true ->
          Memory.pages(2)
          # wasm_memory(min_pages: 2)
          # Memory.pages(min: 2)
          # Memory.pages(increase_by: 2)

          I32.global(
            bump_offset: Constants.bump_init_offset(),
            bump_mark: 0
          )

          @wasm_use_bump_allocator true
      end

      Orb.include(unquote(__MODULE__))

      import unquote(__MODULE__)
    end
  end

  defmodule ExportAlloc do
    @moduledoc false

    defstruct []

    defimpl Orb.ToWat do
      def to_wat(_, indent) do
        [
          indent,
          ~s|(export "alloc" (func $alloc))\n|
        ]
      end
    end
  end

  defmacro export_alloc() do
    quote do
      def __wasm_body__(context) do
        super(context) ++ [%ExportAlloc{}]
      end

      defoverridable __wasm_body__: 1
    end
  end

  Memory.pages(2)

  I32.global(
    bump_offset: Constants.bump_init_offset(),
    bump_mark: 0
  )

  defw alloc(size: I32), I32, [] do
    # TODO: check if we have allocated too much
    # and if so, either err or increase the available memory.
    # TODO: Need better maths than this to round up to aligned memory?

    Orb.Stack.push @bump_offset do
      @bump_offset = I32.add(@bump_offset, size)
    end

    # Better syntax?
    # pop(push: @bump_offset) do
    #   @bump_offset = I32.add(@bump_offset, size)
    # end
  end

  defw free_all() do
    @bump_offset = Constants.bump_init_offset()
  end
end
