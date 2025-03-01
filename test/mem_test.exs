defmodule MemTest do
  use WasmexCase, async: true
  @moduletag timeout: 1000

  alias SilverOrb.Mem

  @moduletag wat: Orb.to_wat(Mem)

  test "wasm size", %{wat: wat} do
    # Just check that the WAT contains expected functions
    assert wat =~ "memcpy"
    assert wat =~ "memset"
  end

  test "memcpy", %{
    call_function: call_function,
    write_binary: write_binary,
    read_binary: read_binary
  } do
    a = 0xA00
    b = 0xB00
    c = 0xC00

    # Write a 32-bit integer to memory
    write_binary.(a, <<0x78, 0x56, 0x34, 0x12>>)

    # Call memcpy
    {:ok, []} = call_function.(:memcpy, [b, a, 3])

    # Read and verify memory contents
    assert read_binary.(a, 4) == <<0x78, 0x56, 0x34, 0x12>>
    assert read_binary.(b, 4) == <<0x78, 0x56, 0x34, 0x00>>

    # Test with zero length copy
    {:ok, []} = call_function.(:memcpy, [c, a, 0])
    assert read_binary.(c, 4) == <<0x00, 0x00, 0x00, 0x00>>
  end

  test "memset", %{call_function: call_function, read_binary: read_binary} do
    # Call memset to fill memory with 'z' characters
    {:ok, []} = call_function.(:memset, [0xA00, ?z, 3])

    # Read and verify memory was set correctly
    assert read_binary.(0xA00 - 1, 6) == <<0x00, ?z, ?z, ?z, 0x00, 0x00>>

    # Test with zero length memset
    {:ok, []} = call_function.(:memset, [0xB00, ?z, 0])
    assert read_binary.(0xB00 - 1, 4) == <<0x00, 0x00, 0x00, 0x00>>
  end
end
