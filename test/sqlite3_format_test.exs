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
    %{pid: pid}
  end

  test "file exists", %{pid: pid} do
    db_bytes = countries_database()

    assert <<
             "SQLite format 3",
             "\0",
             # 2-byte page size
             page_size::16,
             # 1-byte file format write version
             file_format_write_version::8,
             # 1-byte file format read version
             file_format_read_version::8,
             # 1-byte reserved space per page
             reserved_space::8,
             # 1-byte max embedded payload fraction
             max_embedded_payload_fraction::8,
             # 1-byte min embedded payload fraction
             min_embedded_payload_fraction::8,
             # 1-byte leaf payload fraction
             leaf_payload_fraction::8,
             # 4-byte file change counter
             file_change_counter::32,
             # 4-byte database size in pages
             db_size_in_pages::32,
             # 4-byte first freelist trunk page
             first_freelist_page::32,
             # 4-byte total number of freelist pages
             total_freelist_pages::32,
             # 4-byte schema cookie
             schema_cookie::32,
             # 4-byte schema format number
             schema_format::32,
             # 4-byte default page cache size
             default_page_cache_size::32,
             # 4-byte page number of largest B-tree root
             largest_btree_root::32,
             # 4-byte text encoding
             text_encoding::32,
             # 4-byte user version
             user_version::32,
             # 4-byte incremental-vacuum mode
             incremental_vacuum::32,
             # 4-byte application ID
             application_id::32,
             # Reserved space (20 bytes)
             _reserved::binary-size(20),
             # 4-byte version-valid-for number
             version_valid_for::32,
             # 4-byte SQLite version number
             sqlite_version::32,
             # Rest of the binary data
             _rest::binary
           >> = db_bytes

    dbg(page_size)
    dbg(db_size_in_pages)
    dbg(text_encoding)

    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)
    # html = Wasmex.Memory.read_binary(store, memory, ptr, len)
    Wasmex.Memory.write_binary(store, memory, 0x100, db_bytes)

    assert Wasmex.call_function(pid, "read_header", [0x100, byte_size(db_bytes)]) ===
             {:ok, [page_size, db_size_in_pages, text_encoding]}
  end
end
