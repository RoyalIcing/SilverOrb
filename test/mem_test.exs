defmodule MemTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.{Instance, Wasm}
  alias SilverOrb.Mem

  setup do: %{inst: Instance.run(Mem)}

  test "wasm size" do
    wasm = Wasm.to_wasm(Mem)
    assert byte_size(wasm) == 138
  end

  test "convenience calls" do
    assert Mem.memset(dest: 1, u8: 2, byte_count: 3) == %Orb.Instruction{type: Orb.I32, operation: {:call, :memset}, operands: [1, 2, 3]}
  end

  test "memcpy", %{inst: inst} do
    memcpy = Instance.capture(inst, :memcpy, 3)

    a = 0xA00
    b = 0xB00
    c = 0xC00
    Instance.write_i32(inst, a, 0x12345678)
    memcpy.(b, a, 3)
    assert Instance.read_memory(inst, a, 4) == <<0x78, 0x56, 0x34, 0x12>>
    assert Instance.read_memory(inst, b, 4) == <<0x78, 0x56, 0x34, 0x0>>
    memcpy.(c, a, 0)
    assert Instance.read_memory(inst, c, 4) == <<0x0, 0x0, 0x0, 0x0>>
  end

  test "memset", %{inst: inst} do
    memset = Instance.capture(inst, :memset, 3)

    memset.(0xA00, ?z, 3)
    assert Instance.read_memory(inst, 0xA00 - 1, 6) == "\0zzz\0\0"

    memset.(0xB00, ?z, 0)
    assert Instance.read_memory(inst, 0xB00 - 1, 4) == "\0\0\0\0"
  end
end
