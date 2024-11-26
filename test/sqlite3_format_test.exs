defmodule SQLite3FormatTest do
  use ExUnit.Case, async: true

  @countries_database File.read!(Path.join(__DIR__, "sqlite3/countries.sqlite"))

  defp countries_database(), do: @countries_database

  setup do
    wat = Orb.to_wat(SilverOrb.SQLite3Format)
    %{wat: wat}
  end

  setup %{wat: wat} do
    # instance = Instance.run(wat)

    {:ok, pid} = Wasmex.start_link(%{bytes: wat})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)

    call_function = &Wasmex.call_function(pid, &1, &2)
    read_binary = &Wasmex.Memory.read_binary(store, memory, &1, &2)
    write_binary = &Wasmex.Memory.write_binary(store, memory, &1, &2)

    %{
      pid: pid,
      memory: memory,
      store: store,
      call_function: call_function,
      read_binary: read_binary,
      write_binary: write_binary
    }
  end

  test "reading file", %{pid: pid, read_binary: read_binary, write_binary: write_binary} do
    db_bytes = countries_database()

    assert <<
             "SQLite format 3",
             "\0",
             # 2-byte page size
             page_size::16,
             # 1-byte file format write version
             _file_format_write_version::8,
             # 1-byte file format read version
             _file_format_read_version::8,
             # 1-byte reserved space per page
             _reserved_space::8,
             # 1-byte max embedded payload fraction
             _max_embedded_payload_fraction::8,
             # 1-byte min embedded payload fraction
             _min_embedded_payload_fraction::8,
             # 1-byte leaf payload fraction
             _leaf_payload_fraction::8,
             # 4-byte file change counter
             _file_change_counter::32,
             # 4-byte database size in pages
             db_size_in_pages::32,
             # 4-byte first freelist trunk page
             _first_freelist_page::32,
             # 4-byte total number of freelist pages
             _total_freelist_pages::32,
             # 4-byte schema cookie
             _schema_cookie::32,
             # 4-byte schema format number
             _schema_format::32,
             # 4-byte default page cache size
             _default_page_cache_size::32,
             # 4-byte page number of largest B-tree root
             _largest_btree_root::32,
             # 4-byte text encoding
             text_encoding::32,
             # 4-byte user version
             _user_version::32,
             # 4-byte incremental-vacuum mode
             _incremental_vacuum::32,
             # 4-byte application ID
             _application_id::32,
             # Reserved space (20 bytes)
             _reserved::binary-size(20),
             # 4-byte version-valid-for number
             _version_valid_for::32,
             # 4-byte SQLite version number
             _sqlite_version::32,
             # Rest of the binary data
             _rest::binary
           >> = db_bytes

    dbg(page_size)
    dbg(db_size_in_pages)
    dbg(text_encoding)

    ptr = 0x100
    len = byte_size(db_bytes)

    write_binary.(ptr, db_bytes)

    assert Wasmex.call_function(pid, "read_header", [ptr, len]) ===
             {:ok, [page_size, db_size_in_pages, text_encoding]}

    assert page_size == 4096
    assert text_encoding == 1

    assert {:ok, [cell_count, cell_offset]} =
             Wasmex.call_function(pid, "read_btree_table_leaf_header", [ptr + 100, len - 100])

    assert cell_count == 2
    assert cell_offset == 3875

    assert {:ok, [rowid, payload_ptr, payload_size]} =
             Wasmex.call_function(pid, "read_btree_table_leaf_cell", [
               ptr,
               len,
               0,
               0
             ])

    s = read_binary.(payload_ptr, payload_size)

    dbg(cell_count)
    dbg(cell_offset)
    dbg(rowid)
    dbg(payload_ptr)
    dbg(payload_size)
    dbg(s)
  end

  # From https://programmersstone.blog/posts/scrappy-parsing/
  defp parse_varint(bytes, start \\ 0) do
    Enum.reduce_while(0..8, {0, 0}, fn offset, {int, size} ->
      <<high_bit::1, new_int::7>> = binary_part(bytes, start + offset, 1)

      cond do
        size == 8 -> {:halt, {Bitwise.bsl(int, 8) + new_int, size + 1}}
        high_bit == 0 -> {:halt, {Bitwise.bsl(int, 7) + new_int, size + 1}}
        true -> {:cont, {Bitwise.bsl(int, 7) + new_int, size + 1}}
      end
    end)
  end

  test "parse varint", %{call_function: call_function, write_binary: write_binary} do
    assert parse_varint(<<65>>) === {65, 1}
    assert parse_varint(<<127>>) === {127, 1}
    assert parse_varint(<<0x81, 0x23>>) === {163, 2}
    assert parse_varint(<<0xFF, 0x7F>>) === {16383, 2}

    write_binary.(0x100, <<65>>)
    assert call_function.("parse_varint", [0x100]) === {:ok, [65, 1]}

    write_binary.(0x200, <<127>>)
    assert call_function.("parse_varint", [0x200]) === {:ok, [127, 1]}

    write_binary.(0x300, <<0x81, 0x23>>)
    assert call_function.("parse_varint", [0x300]) === {:ok, [163, 2]}

    write_binary.(0x400, <<0xFF, 0x7F>>)
    assert call_function.("parse_varint", [0x400]) === {:ok, [16383, 2]}
  end
end
