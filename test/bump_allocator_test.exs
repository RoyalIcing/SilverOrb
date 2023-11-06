defmodule BumpAllocatorTest do
  use ExUnit.Case, async: true

  alias SilverOrb.BumpAllocator
  alias OrbWasmtime.{Instance, Wasm}

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

  describe "user" do
    defmodule Example do
      use Orb
      use SilverOrb.BumpAllocator

      BumpAllocator.export_alloc()
    end

    test "compiles" do
      Instance.run(Example)

      # assert Example.__wasm_global_type__(:bump_mark) == :i32
    end
  end

  describe "nested user" do
    defmodule A do
      use Orb
      use SilverOrb.BumpAllocator

      wasm do
        func inner_magic(), I32 do
          42 + @bump_offset
        end
      end
    end

    defmodule B do
      use Orb
      use SilverOrb.BumpAllocator

      wasm do
        A.funcp()

        func magic(), I32 do
          typed_call(I32, :inner_magic, [])
        end
      end

      BumpAllocator.export_alloc()
    end

    test "compiles" do
      i = Instance.run(B)
      Instance.call(i, :alloc, 4)
      assert Instance.call(i, :magic) === 65582

      # assert A.__wasm_global_type__(:bump_mark) == :i32
      # assert B.__wasm_global_type__(:bump_mark) == :i32
    end
  end
end
