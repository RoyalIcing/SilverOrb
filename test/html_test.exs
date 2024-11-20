defmodule HTMLTest do
  use ExUnit.Case, async: true

  defmodule HTMLExample do
    use Orb

    Memory.pages(2)
    Orb.include(SilverOrb.HTML)

    # global do
    #   @input_size {i32(0), mutable?: false, export: "input_size"}
    #   @input_size i32(0, mutable?: true, export: "input_size")
    #   @input_size I32.const(0, mutable?: true, export: "input_size")
    # end

    # export do
    global I32, :mutable do
      @input_size 0
      @output_size 0
    end

    # end

    defp input_ptr(), do: 0x0

    defw set_input_size(new_size: I32) do
      @input_size = new_size
    end

    defp output_ptr(), do: Memory.page_byte_size()

    defw read_output(), Str do
      {output_ptr(), @output_size}
    end

    defw count(char: I32.U8), I32 do
      SilverOrb.HTML.escape_char_count(char)
    end

    defw count_input(), I32, input: Memory.Slice, count: I32 do
      input = Memory.Slice.from(i32(input_ptr()), @input_size)
      count = 0

      loop char <- input do
        count = count + SilverOrb.HTML.escape_char_count(char)
      end

      count
    end

    defw escape_input(), input: Memory.Slice, output_so_far: I32, output_size: I32 do
      input = Memory.Slice.from(i32(input_ptr()), @input_size)

      loop char <- input do
        output_so_far =
          output_so_far + SilverOrb.HTML.escape_char(char, output_ptr() + output_so_far)

        # output_so_far =
        #   output_so_far + SilverOrb.HTML.escape_char_block(char, output_ptr() + output_so_far)
      end

      @output_size = output_so_far
    end
  end

  setup do
    wat = Orb.to_wat(HTMLExample)
    # IO.puts(wat)
    %{wat: wat}
  end

  defp expect_0({:ok, []}), do: nil
  defp expect_1({:ok, [value]}), do: value
  defp expect_2({:ok, [first, second]}), do: {first, second}

  setup %{wat: wat} do
    {:ok, pid} = Wasmex.start_link(%{bytes: wat})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)

    call = %{
      count: &expect_1(Wasmex.call_function(pid, "count", [&1])),
      set_input_size: &expect_0(Wasmex.call_function(pid, "set_input_size", [&1])),
      count_input: fn -> expect_1(Wasmex.call_function(pid, "count_input", [])) end,
      escape_input: fn -> expect_0(Wasmex.call_function(pid, "escape_input", [])) end,
      read_output: fn -> expect_2(Wasmex.call_function(pid, "read_output", [])) end
    }

    %{pid: pid, memory: memory, store: store, call: call}
  end

  test "escape count", %{store: store, memory: memory, call: call} do
    assert call.count.(?a) === 1
    assert call.count.(?&) === 5
    assert call.count.(?") === 6
    assert call.count.(?') === 5

    assert call.count_input.() === 0
    input = "bangers & mash"
    Wasmex.Memory.write_binary(store, memory, 0x0, input)
    call.set_input_size.(byte_size(input))
    assert call.count_input.() === 18
  end

  test "escape", %{store: store, memory: memory, call: call} do
    input = "bangers & mash"
    Wasmex.Memory.write_binary(store, memory, 0x0, input)
    call.set_input_size.(byte_size(input))

    # t_start = NaiveDateTime.utc_now()
    # Enum.each(0..10_000, fn _ ->
    #   call.escape_input.()
    # end)
    # t_end = NaiveDateTime.utc_now()
    # IO.inspect(NaiveDateTime.diff(t_end, t_start, :millisecond), label: "DURATION")

    call.escape_input.()

    {output_ptr, output_len} = call.read_output.()
    output = Wasmex.Memory.read_string(store, memory, output_ptr, output_len)

    assert output === "bangers &amp; mash"
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
