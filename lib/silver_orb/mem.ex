defmodule SilverOrb.Mem do
  @moduledoc """
  memcpy and memset for Orb.

  ```elixir
  defmodule Example do
    use Orb
    use SilverOrb.Mem

  end
  ```
  """

  use Orb

  defmacro __using__(_opts) do
    quote do
      import Orb

      wasm do
        unquote(__MODULE__).funcp()
      end

      import unquote(__MODULE__)
    end
  end

  Memory.pages(2)

  wasm U32 do
    func memcpy(dest: I32.U8.UnsafePointer, src: I32.U8.UnsafePointer, byte_count: I32),
      i: I32 do
      loop EachByte do
        return(if: I32.eq(i, byte_count))

        dest[at!: i] = src[at!: i]

        i = i + 1
        EachByte.continue()
      end

      # loop EachByte, count: byte_count do
      #   i ->
      #     I32.u! do
      #       memory32_8![dest + i] = memory32_8![src + i]
      #     end
      # end

      #         loop :each_byte do
      #           memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
      #
      #           if I32.lt_u(i, byte_count) do
      #             i = I32.add(i, 1)
      #             :each_byte
      #           end
      #         end

      #         loop :i do
      #           memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
      #
      #           if I32.lt_u(i, byte_count) do
      #             i = I32.add(i, 1)
      #             {:br, :i}
      #           end
      #         end

      #       loop i, 0..byte_count do
      #         memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
      #       end

      #       loop i, I32.lt_u(byte_count), I32.add(1) do
      #         memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
      #       end

      #       loop i, I32.add do
      #         i ->
      #           memory32_8![I32.add(dest, i)] = memory32_8![I32.add(src, i)].unsigned
      #
      #           I32.lt_u(i, byte_count)
      #       end
    end

    # TODO: add 32-bit-aligned version so we can use faster instructions.
    func memset(dest: I32.U8.UnsafePointer, u8: I32.U8, byte_count: I32),
      i: I32 do
      loop EachByte do
        return(if: I32.eq(i, byte_count))

        dest[at!: i] = u8

        i = i + 1
        EachByte.continue()
      end
    end
  end

  def memcpy(dest, src, byte_count) do
    Orb.DSL.call(:memcpy, dest, src, byte_count)
  end

  def memcpy(dest: dest, src: src, byte_count: byte_count) do
    Orb.DSL.call(:memcpy, dest, src, byte_count)
  end

  def memset(dest: dest, u8: u8, byte_count: byte_count) do
    Orb.DSL.call(:memset, dest, u8, byte_count)
  end
end
