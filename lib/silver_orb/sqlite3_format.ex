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

  defmodule Log do
    use Orb.Import, name: :log

    defw(u32(u: I32))
    defw(u64(u: I64))
    defw(utf8(ptr: I32.UnsafePointer, size: I32))
    defw(bytes(ptr: I32.UnsafePointer, size: I32))

    def four_cc(binary) when is_binary(binary) and byte_size(binary) == 4 do
      four_cc(I32.from_4_byte_ascii(binary))
    end

    defw(four_cc(four_cc: I32))

    defw(putc(utf8char: I32))

    def puts(<<utf8char::utf8, rest::binary>>) do
      Orb.snippet do
        putc(utf8char)
        puts(rest)
      end
    end

    def puts("") do
      putc(?\n)
    end

    def utf8_slice(slice) do
      utf8(Memory.Slice.get_byte_offset(slice), Memory.Slice.get_byte_length(slice))
    end

    def str(str) do
      utf8_slice(Str.to_slice(str))
    end
  end

  # if Mix.env() == :test do
  Orb.Import.register(Log)
  # end

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
       column5_size: I32 do
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
      column5_ptr,
      column5_size
    }
  end

  # defwi decode_text_size(column: I32) :: I32, do: I32.div_u(column - 13, 2)

  defw read_table_schema(ptr: I32.UnsafePointer, len: I32),
       {I32, I32.UnsafePointer, I32, I32},
       seek_ptr: I32,
       header_bytes: I32,
       column_type: I32,
       column_type_ptr: I32.UnsafePointer,
       column_type_size: I32,
       column_name: I32,
       column_name_ptr: I32.UnsafePointer,
       column_name_size: I32,
       column_tbl_name: I32,
       column_tbl_name_ptr: I32.UnsafePointer,
       column_tbl_name_size: I32,
       column_rootpage: I32,
       column_rootpage_ptr: I32.UnsafePointer,
       column_rootpage_size: I32,
       column_sql: I32,
       column_sql_ptr: I32.UnsafePointer,
       column_sql_size: I32,
       table_column_count: I32 do
    seek_ptr = ptr
    header_bytes = parse_varint(mut!(seek_ptr))
    column_type = parse_varint(mut!(seek_ptr))
    column_name = parse_varint(mut!(seek_ptr))
    column_tbl_name = parse_varint(mut!(seek_ptr))
    column_rootpage = parse_varint(mut!(seek_ptr))
    column_sql = parse_varint(mut!(seek_ptr))

    seek_ptr = ptr + header_bytes

    column_type_ptr = seek_ptr
    column_type_size = I32.div_u(column_type - 13, 2)
    seek_ptr = seek_ptr + column_type_size

    assert!(Memory.load!(I32, column_type_ptr) === I32.from_4_byte_ascii("tabl"))

    column_name_ptr = seek_ptr
    column_name_size = I32.div_u(column_name - 13, 2)
    seek_ptr = seek_ptr + column_name_size

    column_tbl_name_ptr = seek_ptr
    column_tbl_name_size = I32.div_u(column_tbl_name - 13, 2)
    seek_ptr = seek_ptr + column_tbl_name_size

    column_rootpage_ptr = seek_ptr
    seek_ptr = seek_ptr + 1

    column_sql_ptr = seek_ptr
    column_sql_size = I32.div_u(column_sql - 13, 2)
    seek_ptr = seek_ptr + column_sql_size

    table_column_count = parse_create_table_sql(column_sql_ptr, column_sql_size)

    {
      header_bytes,
      column_sql_ptr,
      column_sql_size,
      table_column_count
    }
  end

  defmodule TableSchemaColumns3Result do
    def fields() do
      [
        table_column_count: I32,
        col_1_str_ptr: I32.UnsafePointer,
        col_1_str_size: I32,
        col_1_flags: I32,
        col_2_str_ptr: I32.UnsafePointer,
        col_2_str_size: I32,
        col_2_flags: I32,
        col_3_str_ptr: I32.UnsafePointer,
        col_3_str_size: I32,
        col_3_flags: I32
      ]
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

  # defp state_table_name, do: 0
  # defp state_column_name, do: 1
  # defp state_between_columns, do: 2

  defp column_affinity_none, do: 0b0000_0000
  defp column_affinity_text, do: 0b0000_0001
  defp column_affinity_numeric, do: 0b0000_0010
  defp column_affinity_integer, do: 0b0000_0011
  defp column_affinity_real, do: 0b0000_0100
  defp column_not_null, do: 0b0000_1000
  defp column_primary_key, do: 0b0001_0000

  defw parse_table_schema_columns_3(ptr: I32.UnsafePointer, len: I32),
       TableSchemaColumns3Result,
       seek_ptr: I32,
       seek_slice: Memory.Slice,
       parse_state: I32,
       parsing_column: I32,
       table_column_count: I32,
       col_1_str_ptr: I32.UnsafePointer,
       col_1_str_size: I32,
       col_1_flags: I32,
       col_2_str_ptr: I32.UnsafePointer,
       col_2_str_size: I32,
       col_2_flags: I32,
       col_3_str_ptr: I32.UnsafePointer,
       col_3_str_size: I32,
       col_3_flags: I32 do
    seek_ptr = ptr

    must! do
      Memory.load!(I32, seek_ptr) === I32.from_4_byte_ascii("CREA")
      Memory.load!(I32, seek_ptr + 4) === I32.from_4_byte_ascii("TE T")
      Memory.load!(I32, seek_ptr + 8) === I32.from_4_byte_ascii("ABLE")
      Memory.load!(I32.U8, seek_ptr + 12) === 0x20
    end

    seek_slice = Memory.Slice.from(seek_ptr + 13, len)

    parse_state = const(:table_name)

    loop char <- seek_slice do
      cond result: nil do
        parse_state === const(:table_name) ->
          if char === 0x20 do
            parse_state = const(:before_columns)
          end

        parse_state === const(:before_columns) or parse_state === const(:between_columns) ->
          if not (char === ?( or char === ?\n or char === 0x20) do
            if char === ?) do
              parse_state = const(:after_columns)
            else
              parse_state = const(:column_name)

              if parsing_column === 0 do
                parsing_column = 1
              end

              if parsing_column === 1 do
                col_1_str_ptr = Memory.Slice.get_byte_offset(seek_slice)
              end

              if parsing_column === 2 do
                col_2_str_ptr = Memory.Slice.get_byte_offset(seek_slice)
              end

              if parsing_column === 3 do
                col_3_str_ptr = Memory.Slice.get_byte_offset(seek_slice)
              end
            end
          end

        parse_state === const(:column_name) ->
          if char === 0x20 do
            if parsing_column === 1 do
              col_1_str_size = Memory.Slice.get_byte_offset(seek_slice) - col_1_str_ptr
            end

            if parsing_column === 2 do
              col_2_str_size = Memory.Slice.get_byte_offset(seek_slice) - col_2_str_ptr
            end

            if parsing_column === 3 do
              col_3_str_size = Memory.Slice.get_byte_offset(seek_slice) - col_3_str_ptr
            end

            parse_state = const(:column_type)
          end

        parse_state === const(:column_type) ->
          Log.puts("column_type")
          Log.u32(char)

          if char === ?) do
            parse_state = const(:after_columns)
          end

          if char === ?, do
            Log.puts("comma")
            parse_state = const(:between_columns)
          end

          if parse_state === const(:column_type) do
            if parsing_column === 1 do
              {seek_slice, col_1_flags} = parse_column_type(seek_slice)
              Log.four_cc("COL1")
              Log.u32(parsing_column)
              Log.u32(col_1_flags)

              if col_1_flags do
                # FIXME: The loop will increment the slice, so rewind one character.
                seek_slice =
                  Memory.Slice.from(
                    Memory.Slice.get_byte_offset(seek_slice) - 1,
                    Memory.Slice.get_byte_length(seek_slice) + 1
                  )
              end

              # col_1_flags = 1
            end

            # char = Memory.load!(I32.U8, Memory.Slice.get_byte_offset(seek_slice))

            # if char === ?) do
            #   parse_state = const(:after_columns)
            # end

            # if char === ?, do
            #   Log.puts("comma")
            #   parse_state = const(:between_columns)
            # end
          end

          if parse_state !== const(:column_type) do
            parsing_column = parsing_column + 1
            table_column_count = table_column_count + 1
          end
      end
    end

    # assert! Memory.Slice.read!(mut!(input), I32) === I32.from_4_byte_ascii("CREA")
    # assert! Memory.Slice.read!(mut!(input), I32) === I32.from_4_byte_ascii("TE T")
    # assert! Memory.Slice.read!(mut!(input), I32) === I32.from_4_byte_ascii("ABLE")

    Log.u32(99)
    Log.u32(col_1_flags)

    [
      table_column_count: table_column_count,
      col_1_str_ptr: col_1_str_ptr,
      col_1_str_size: col_1_str_size,
      col_1_flags: col_1_flags,
      col_2_str_ptr: col_2_str_ptr,
      col_2_str_size: col_2_str_size,
      col_2_flags: col_2_flags,
      col_3_str_ptr: col_3_str_ptr,
      col_3_str_size: col_3_str_size,
      col_3_flags: col_3_flags
    ]
    |> Keyword.values()
    |> List.to_tuple()
  end

  defwp parse_column_type(slice: Memory.Slice), {Memory.Slice, I32}, flags: I32 do
    # Log.u32(const("parse_column_type").memory_offset)
    # Log.utf8(const("parse_column_type").memory_offset, byte_size("parse_column_type"))
    # Log.utf8_slice(Str.to_slice("parse_column_type"))
    Log.utf8_slice(slice)
    # Log.str("\n")
    Log.u32(Memory.load!(I32.U8, Memory.Slice.get_byte_offset(slice)))
    Log.u32(Memory.Slice.get_byte_length(slice) >= 5)

    Log.u32(
      Memory.load!(I32, Memory.Slice.get_byte_offset(slice)) === I32.from_4_byte_ascii("TEXT")
    )

    Log.u32(Memory.load!(I32.U8, Memory.Slice.get_byte_offset(slice) + 4) === 0x20)

    # flags = Memory.load!(I32, Memory.Slice.get_byte_offset(slice))
    # flags = Memory.Slice.get_byte_length(slice)

    if Memory.Slice.get_byte_length(slice) >= 5 &&&
         Memory.load!(I32, Memory.Slice.get_byte_offset(slice)) ===
           I32.from_4_byte_ascii("TEXT") &&&
         Memory.load!(I32.U8, Memory.Slice.get_byte_offset(slice) + 4) === 0x20 do
      flags = column_affinity_text()
      Log.puts("flags:")
      Log.u32(flags)

      slice =
        Memory.Slice.from(
          Memory.Slice.get_byte_offset(slice) + 5,
          Memory.Slice.get_byte_length(slice) - 5
        )

      {slice, flags} = parse_column_primary_key(slice, flags)
      {slice, flags} = parse_column_not_null(slice, flags)

      Log.puts("flags:")
      Log.u32(flags)
    else
      flags = 0
    end

    Log.u32(flags)

    {slice, flags}
  end

  defwp parse_column_primary_key(slice: Memory.Slice, flags: I32), {Memory.Slice, I32} do
    Log.u32(13)
    Log.puts("parse_column_primary_key")
    Log.utf8_slice(slice)
    Log.u32(Memory.Slice.get_byte_length(slice))
    Log.four_cc(Memory.load!(I32, Memory.Slice.get_byte_offset(slice)))
    Log.four_cc(Memory.load!(I32, Memory.Slice.get_byte_offset(slice) + 4))
    Log.four_cc(Memory.load!(I32, Memory.Slice.get_byte_offset(slice) + 8))

    if Memory.Slice.get_byte_length(slice) >= 12 &&&
         Memory.load!(I32, Memory.Slice.get_byte_offset(slice)) ===
           I32.from_4_byte_ascii("PRIM") &&&
         Memory.load!(I32, Memory.Slice.get_byte_offset(slice) + 4) ===
           I32.from_4_byte_ascii("ARY ") &&&
         (Memory.load!(I32, Memory.Slice.get_byte_offset(slice) + 8) &&&
            I32.from_4_byte_ascii("KEY\0")) === I32.from_4_byte_ascii("KEY\0") do
      flags = flags ||| column_primary_key()

      Log.puts("before:")
      Log.u32(Memory.Slice.get_byte_offset(slice))

      slice =
        Memory.Slice.from(
          Memory.Slice.get_byte_offset(slice) + 11,
          Memory.Slice.get_byte_length(slice) - 11
        )

      Log.puts("after:")
      Log.u32(Memory.Slice.get_byte_offset(slice))
    end

    Log.utf8_slice(slice)

    {slice, flags}
  end

  defwp parse_column_not_null(slice: Memory.Slice, flags: I32), {Memory.Slice, I32} do
    if Memory.Slice.get_byte_length(slice) >= 9 &&&
         Memory.load!(I32, Memory.Slice.get_byte_offset(slice)) ===
           I32.from_4_byte_ascii("NOT ") &&&
         Memory.load!(I32, Memory.Slice.get_byte_offset(slice) + 4) ===
           I32.from_4_byte_ascii("NULL") do
      flags = flags ||| column_not_null()

      slice =
        Memory.Slice.from(
          Memory.Slice.get_byte_offset(slice) + 8,
          Memory.Slice.get_byte_length(slice) - 8
        )
    end

    {slice, flags}
  end

  # defp do_slice_equals_string(slice, <<first_four::binary-size(4), rest::binary>>) do
  #   Orb.snippet do
  #     Memory.load!(I32, Memory.Slice.get_byte_offset(slice)) ===
  #       I32.from_4_byte_ascii(const(first_four)) and
  #       slice_equals_string(
  #         Memory.Slice.from(Memory.Slice.get_byte_offset(slice) + 4, Memory.Slice.size(slice) - 4)
  #         Memory.Slice.drop_first_byte(
  #           Memory.Slice.drop_first_byte(
  #             Memory.Slice.drop_first_byte(Memory.Slice.drop_first_byte(slice))
  #           )
  #         ),
  #         rest
  #       )
  #   end
  # end

  defwp parse_create_table_sql(ptr: I32.UnsafePointer, len: I32), I32,
    count: I32,
    input: Memory.Slice do
    assert!(Memory.load!(I32, ptr) === I32.from_4_byte_ascii("CREA"))
    assert!(Memory.load!(I32, ptr + 4) === I32.from_4_byte_ascii("TE T"))
    assert!(Memory.load!(I32, ptr + 8) === I32.from_4_byte_ascii("ABLE"))

    input = Memory.Slice.from(ptr + 12, len)

    # assert! Memory.Slice.read!(mut!(input), I32) === I32.from_4_byte_ascii("CREA")
    # assert! Memory.Slice.read!(mut!(input), I32) === I32.from_4_byte_ascii("TE T")
    # assert! Memory.Slice.read!(mut!(input), I32) === I32.from_4_byte_ascii("ABLE")

    loop char <- input do
      if char === ?, or char === ?) do
        count = count + 1
      end
    end

    count
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
