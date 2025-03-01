defmodule ICOTest do
  use ExUnit.Case, async: true

  setup do
    wat = Orb.to_wat(SilverOrb.ICO)
    %{wat: wat}
  end

  setup %{wat: wat} do
    {:ok, pid} = Wasmex.start_link(%{bytes: wat})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)

    call_function = &Wasmex.call_function(pid, &1, &2)
    read_binary = &Wasmex.Memory.read_binary(store, memory, &1, &2)
    write_binary = &Wasmex.Memory.write_binary(store, memory, &1, &2)

    %{
      pid: pid,
      memory: memory,
      store: store,
      call_function: call_function,
      read_binary: read_binary,
      write_binary: write_binary
    }
  end

  test "write pink ico file", %{call_function: call_function, read_binary: read_binary} do
    path = Path.join(__DIR__, "pink.ico")

    write_ptr = Orb.Memory.page_byte_size()
    # {:ok, [byte_count]} = call_function.(:write, [write_ptr, 16, 16, 0x000000FF - 0x80000000])
    {:ok, [byte_count]} = call_function.(:write, [write_ptr, 32, 32, 0xFF, 0x11, 0xBB])

    bytes = read_binary.(write_ptr, byte_count)
    File.write!(path, bytes)
  end
end
