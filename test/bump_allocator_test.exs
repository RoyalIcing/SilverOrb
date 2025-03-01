defmodule BumpAllocatorTest do
  use WasmexCase, async: true

  alias SilverOrb.BumpAllocator

  @moduletag wat: Orb.to_wat(BumpAllocator)

  test "compiles", %{pid: pid} do
    # Verify the module loaded successfully
    assert pid != nil
  end

  test "wasm size", %{wat: wat} do
    # Just check the WAT string
    assert wat =~ "alloc"
    assert wat =~ "free_all"
  end

  test "single allocation", %{call_function: call_function} do
    {:ok, [result]} = call_function.(:alloc, [16])
    assert result == 64 * 1024
  end

  test "multiple allocations", %{call_function: call_function} do
    # Test multiple allocations
    {:ok, [addr1]} = call_function.(:alloc, [0x10])
    assert addr1 == 0x10000

    {:ok, [addr2]} = call_function.(:alloc, [0x10])
    assert addr2 == 0x10010

    {:ok, [addr3]} = call_function.(:alloc, [0x10])
    assert addr3 == 0x10020

    # Free all allocations
    {:ok, []} = call_function.(:free_all, [])

    # Verify memory is reset
    {:ok, [addr4]} = call_function.(:alloc, [0x10])
    assert addr4 == 0x10000

    {:ok, [addr5]} = call_function.(:alloc, [0x10])
    assert addr5 == 0x10010

    {:ok, [addr6]} = call_function.(:alloc, [0x10])
    assert addr6 == 0x10020
  end

  describe "user" do
    defmodule Example do
      use Orb
      use SilverOrb.BumpAllocator

      BumpAllocator.export_alloc()
    end

    test "compiles" do
      wat = Orb.to_wat(Example)
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      assert pid != nil

      # assert Example.__wasm_global_type__(:bump_mark) == :i32
    end
  end

  describe "nested user" do
    defmodule A do
      use Orb
      use SilverOrb.BumpAllocator

      defw inner_magic(), I32 do
        42 + @bump_offset
      end
    end

    defmodule B do
      use Orb
      use SilverOrb.BumpAllocator

      Orb.include(A)

      defw magic(), I32 do
        Orb.Instruction.typed_call(I32, [], :inner_magic, [])
      end

      BumpAllocator.export_alloc()
    end

    test "compiles" do
      wat = Orb.to_wat(B)
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})

      {:ok, [_]} = Wasmex.call_function(pid, :alloc, [4])
      {:ok, [result]} = Wasmex.call_function(pid, :magic, [])
      assert result === 65582

      # assert A.__wasm_global_type__(:bump_mark) == :i32
      # assert B.__wasm_global_type__(:bump_mark) == :i32
    end
  end
end
