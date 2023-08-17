defmodule BumpAllocatorTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.{Instance, Wasm}
  alias SilverOrb.BumpAllocator

  test "compiles" do
    Instance.run(BumpAllocator)
  end

  test "wasm size" do
    wasm = Wasm.to_wasm(BumpAllocator)
    assert byte_size(wasm) == 99
  end

  test "single allocation" do
    assert Wasm.call(BumpAllocator, :alloc, 16) == 64 * 1024
  end

  test "multiple allocations" do
    inst = Instance.run(BumpAllocator)
    alloc = Instance.capture(inst, :alloc, 1)
    free_all = Instance.capture(inst, :free_all, 0)

    assert alloc.(0x10) == 0x10000
    assert alloc.(0x10) == 0x10010
    assert alloc.(0x10) == 0x10020
    free_all.()
    assert alloc.(0x10) == 0x10000
    assert alloc.(0x10) == 0x10010
    assert alloc.(0x10) == 0x10020
  end
end
