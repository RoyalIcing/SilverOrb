defmodule CRCTest do
  use WasmexCase, async: true

  @moduletag wat: Orb.to_wat(SilverOrb.CRC)

  test "crc32/2", %{
    pid: pid,
    store: store,
    memory: memory,
    call_function: call_function,
    write_binary: write_binary
  } do
    assert 0 = wasm_crc32(pid, store, memory, call_function, write_binary, "")
    assert 0 = :erlang.crc32("")

    assert 0x3610A686 = wasm_crc32(pid, store, memory, call_function, write_binary, "hello")
    assert 0x3610A686 = :erlang.crc32("hello")

    Enum.each(1..1024, fn n ->
      bytes = :crypto.strong_rand_bytes(n)

      assert wasm_crc32(pid, store, memory, call_function, write_binary, bytes) ===
               :erlang.crc32(bytes)
    end)
  end

  defp wasm_crc32(_pid, _store, _memory, call_function, write_binary, s) when is_binary(s) do
    input_ptr = Orb.Memory.page_byte_size()

    # Write binary directly (no need to convert to list)
    write_binary.(input_ptr, s)

    # Call the function
    {:ok, [result]} = call_function.(:crc32, [input_ptr, byte_size(s)])

    # Handle negative values (convert to unsigned if needed)
    if result < 0, do: 0x1_0000_0000 + result, else: result
  end
end
