defmodule CRCTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  test "crc32/2" do
    wat = Orb.to_wat(SilverOrb.CRC)
    i = Instance.run(wat)

    assert 0 = wasm_crc32(i, "")
    assert 0 = :erlang.crc32("")

    assert 0x3610A686 = wasm_crc32(i, "hello")
    assert 0x3610A686 = :erlang.crc32("hello")

    Enum.each(1..1024, fn n ->
      a = :crypto.strong_rand_bytes(n)
      assert wasm_crc32(i, a) === :erlang.crc32(a)
    end)
  end

  defp wasm_crc32(i, s) when is_binary(s) do
    input_ptr = Orb.Memory.page_byte_size()

    bytes = s |> :binary.bin_to_list()

    Instance.write_memory(i, input_ptr, bytes)
    result = Instance.call(i, :crc32, input_ptr, length(bytes))
    if result < 0, do: 0x1_0000_0000 + result, else: result
  end
end
