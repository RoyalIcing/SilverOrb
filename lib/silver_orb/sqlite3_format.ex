# defmodule Orb.I32.U16 do
#   @moduledoc """
#   Type for unsigned 32-bit integer interpreted as unsigned 16-bit (double byte).
#   """

#   with @behaviour Orb.CustomType do
#     @impl Orb.CustomType
#     def wasm_type(), do: :i32

#     @impl Orb.CustomType
#     def load_instruction(), do: :load16_u
#   end
# end

defmodule SilverOrb.SQLite3Format do
  @moduledoc """
  Reads the SQLite format: https://www.sqlite.org/fileformat.html
  """
  use Orb

  Memory.pages(100)

  # defw read(source: [ptr: I32.UnsafePointer, len: I32]) do
  # end

  defw read_header(ptr: I32.UnsafePointer, len: I32), {I32, I32, I32} do
    inline do
      for {char!, index!} <- Enum.with_index(String.to_charlist("SQLite format 3\0")) do
        wasm do
          assert!(Memory.load!(I32.U8, ptr + index!) === char!)
        end
      end
    end

    {
      # page size
      load_u16_be!(ptr + 16),
      # page count
      load_u32_be!(ptr + 28),
      # text encoding
      load_u32_be!(ptr + 56)
    }
  end

  defwp load_u16_be!(ptr: I32.UnsafePointer), I32 do
    Memory.load!(I32.U8, ptr) <<< 8 ||| Memory.load!(I32.U8, ptr + 1)
  end

  defwp load_u32_be!(ptr: I32.UnsafePointer), I32 do
    Memory.load!(I32.U8, ptr) |> I32.shl(24) |||
      Memory.load!(I32.U8, ptr + 1) |> I32.shl(16) |||
      Memory.load!(I32.U8, ptr + 2) |> I32.shl(8) |||
      Memory.load!(I32.U8, ptr + 3)
  end
end
