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

  # See also: https://programmersstone.blog/posts/scrappy-parsing/
  # https://mrsuh.com/articles/2024/sqlite-index-visualization-structure/

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

  defw read_btree_header(ptr: I32.UnsafePointer, len: I32), {I32, I32, I32, I32} do
    {
      # page type
      Memory.load!(I32.U8, ptr),
      # first freeblock offset
      load_u16_be!(ptr + 1),
      # cell count
      load_u16_be!(ptr + 3),
      # cell content area offset
      load_u16_be!(ptr + 5)
    }
  end

  defw read_create_table_statement(ptr: I32.UnsafePointer, len: I32), I32 do
    0
  end

  defw read_btree_table_leaf_header(ptr: I32.UnsafePointer, len: I32), {I32, I32},
    cell_count: I32,
    cell_offset: I32 do
    assert!(Memory.load!(I32.U8, ptr) === 0x0D)
    cell_count = load_u16_be!(ptr + 3)
    cell_offset = load_u16_be!(ptr + 5)
    {cell_count, cell_offset}
  end

  defw read_btree_table_leaf_cell(
         ptr: I32.UnsafePointer,
         len: I32,
         page_index: I32,
         cell_index: I32
       ),
       {I32, I32, I32},
       cell_start: I32.UnsafePointer,
       content_start: I32.UnsafePointer,
       payload_size: I32,
       payload_byte_size: I32,
       rowid: I32,
       rowid_byte_size: I32 do
    cell_start = ptr + 100 + 8
    content_start = ptr + load_u16_be!(cell_start)

    {payload_size, payload_byte_size} = parse_varint(content_start)
    {rowid, rowid_byte_size} = parse_varint(content_start + payload_byte_size)

    {
      rowid,
      content_start + payload_byte_size + rowid_byte_size,
      payload_size
    }
  end

  defw read_record(ptr: I32.UnsafePointer, len: I32),
       {I32, I32.UnsafePointer, I32},
       seek_ptr: I32,
       header_bytes: I32,
       column1: I32,
       column1_ptr: I32.UnsafePointer,
       column1_size: I32,
       column2: I32,
       column2_ptr: I32.UnsafePointer,
       column2_size: I32,
       column3: I32,
       column3_ptr: I32.UnsafePointer,
       column3_size: I32,
       column4: I32,
       column4_ptr: I32.UnsafePointer,
       column4_size: I32,
       column5: I32,
       column5_ptr: I32.UnsafePointer,
       column5_size: I32
       do
    seek_ptr = ptr
    header_bytes = parse_varint(mut!(seek_ptr))
    column1 = parse_varint(mut!(seek_ptr))
    column2 = parse_varint(mut!(seek_ptr))
    column3 = parse_varint(mut!(seek_ptr))
    column4 = parse_varint(mut!(seek_ptr))
    column5 = parse_varint(mut!(seek_ptr))
    
    seek_ptr = ptr + header_bytes
    
    column1_ptr = seek_ptr
    column1_size = I32.div_u(column1 - 13, 2)
    seek_ptr = seek_ptr + column1_size
    
    column2_ptr = seek_ptr
    column2_size = I32.div_u(column2 - 13, 2)
    seek_ptr = seek_ptr + column2_size
    
    column3_ptr = seek_ptr
    column3_size = I32.div_u(column3 - 13, 2)
    seek_ptr = seek_ptr + column3_size
    
    column4_ptr = seek_ptr
    seek_ptr = seek_ptr + 1
    
    column5_ptr = seek_ptr
    column5_size = I32.div_u(column5 - 13, 2)
    seek_ptr = seek_ptr + column5_size

    {
      header_bytes,
      # column1_ptr,
      # column1_size
      column5_ptr,
      column5_size
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

  def parse_varint(ptr_mut!) when is_struct(ptr_mut!, Orb.MutRef) do
    %Orb.InstructionSequence{
      body: [
        parse_varint(ptr_mut!.read),
        I32.add(ptr_mut!.read, Orb.Stack.pop(I32)),
        ptr_mut!.write
      ],
      push_type: I32
    }
  end

  # TODO: change return value to {I64, I32}
  defw parse_varint(ptr: I32.UnsafePointer), {I32, I32},
    int: I32,
    size: I32,
    new_int: I32,
    high_bit: I32 do
    loop offset <- 0..8 do
      new_int = Memory.load!(I32.U8, ptr + offset)
      high_bit = new_int &&& 0b1000_0000
      new_int = new_int &&& 0b0111_1111
      # <<high_bit::1, new_int::7>> = Memory.load!(I32.U8, ptr + 0)

      if size === 8 do
        return(%Orb.InstructionSequence{body: [{(int <<< 8) + new_int, size + 1}]})
      end

      if high_bit === 0 do
        return(%Orb.InstructionSequence{body: [{(int <<< 7) + new_int, size + 1}]})
      end

      int = (int <<< 7) + new_int
      size = size + 1
    end

    {int, size}
  end
end
