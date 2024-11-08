defmodule HTMLTest do
  use ExUnit.Case, async: true

  defmodule HTMLExample do
    use Orb

    Memory.pages(1)
    Orb.include(SilverOrb.HTML)

    defw count(char: I32.U8), I32 do
      SilverOrb.HTML.approach_single_count(char)
    end
  end

  setup do
    wat = Orb.to_wat(HTMLExample)
    # IO.puts(wat)
    %{wat: wat}
  end

  defp expect_1({:ok, [value]}), do: value

  setup %{wat: wat} do
    {:ok, pid} = Wasmex.start_link(%{bytes: wat})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)

    call = %{
      count: &expect_1(Wasmex.call_function(pid, "count", [&1]))
    }

    %{pid: pid, memory: memory, store: store, call: call}
  end

  test "count", %{store: store, memory: memory, call: call} do
    assert call.count.(?a) === 1
    assert call.count.(?&) === 5
    assert call.count.(?") === 6
    assert call.count.(?') === 5
  end

  #   test "escapes html", %{pid: pid, store: store, memory: memory} do
  #     html = Wasmex.Memory.read_binary(store, memory, ptr, len)
  #     ptr = 0x100
  #     len = byte_size(db_bytes)
  # 
  #     Wasmex.Memory.write_binary(store, memory, ptr, db_bytes)
  # 
  #     assert Wasmex.call_function(pid, "read_header", [ptr, len]) ===
  #              {:ok, [page_size, db_size_in_pages, text_encoding]}
  # 
  #     assert {:ok, [cell_count, cell_offset]} =
  #              Wasmex.call_function(pid, "read_btree_table_leaf_header", [ptr + 100, len - 100])
  # 
  #     assert {:ok, [byte_count_0, byte_count_1]} =
  #              Wasmex.call_function(pid, "read_btree_table_leaf_cell", [
  #                cell_offset,
  #                len - cell_offset
  #              ])
  # 
  #     dbg(cell_count)
  #     dbg(cell_offset)
  #     dbg(byte_count_0)
  #     dbg(byte_count_1)
  #   end
end
