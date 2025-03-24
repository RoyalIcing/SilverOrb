defmodule SilverOrb.ArenaTest do
  use WasmexCase, async: true

  defmodule A do
    use Orb
    alias require SilverOrb.Arena

    Arena.def(First, pages: 2)
    Arena.def(Second, pages: 3)
    Arena.def(Third, pages: 3, max_pages: 5)

    defw example(), a: I32.UnsafePointer, b: I32.UnsafePointer do
      a = First.alloc!(4)
      Memory.store!(I32, a, 42)

      b = Second.alloc!(4)
      Memory.store!(I32, b, 99)

      assert!(a !== First.alloc!(4))
      First.rewind()
      assert!(a === First.alloc!(4))
    end

    defw test(), {I32, I32, I32, I32} do
      # First.stack do
      #   a = 16
      #   b = 45

      #   other_function(a)
      # end

      First.alloc!(16)
      First.alloc!(16)
      Second.alloc!(16)
      First.rewind()
      First.alloc!(16)
    end

    defw just_enough(), I32, i: I32, final: I32 do
      loop AllocManyTimes do
        final = First.alloc!(16)

        i = i + 1
        AllocManyTimes.continue(if: i < 2 * 64 * 1024 / 16)
      end

      final
    end

    defw too_many(), i: I32 do
      loop AllocManyTimes do
        _ = First.alloc!(16)

        i = i + 1
        AllocManyTimes.continue(if: i <= 2 * 64 * 1024 / 16)
      end
    end

    defw within_max_pages(), I32 do
      _ = Third.alloc!(64 * 1024)
      _ = Third.alloc!(64 * 1024)
      _ = Third.alloc!(64 * 1024)
      _ = Third.alloc!(64 * 1024)
      Third.alloc!(64 * 1024)
    end

    defw over_max_pages() do
      _ = Third.alloc!(64 * 1024)
      _ = Third.alloc!(64 * 1024)
      _ = Third.alloc!(64 * 1024)
      _ = Third.alloc!(64 * 1024)
      _ = Third.alloc!(64 * 1024)
      _ = Third.alloc!(64 * 1024)
    end

    defw memory_page_count(), I32 do
      Memory.size()
    end
  end

  test "allocates correct amount of memory" do
    assert A.to_wat() =~ ~S|(memory (export "memory") 8)|
  end

  test "declares globals for each bump offset" do
    assert A.to_wat() =~ ~S"""
             (global $SilverOrb.ArenaTest.A.First.bump_offset (mut i32) (i32.const 0))
             (global $SilverOrb.ArenaTest.A.Second.bump_offset (mut i32) (i32.const 131072))
             (global $SilverOrb.ArenaTest.A.Third.bump_offset (mut i32) (i32.const 327680))
           """
  end

  test "add func prefixes" do
    assert A.to_wat() =~ ~S"""
             (func $SilverOrb.ArenaTest.A.First.alloc! (param $byte_count i32) (result i32)
           """

    assert A.to_wat() =~ ~s"""
             (func $SilverOrb.ArenaTest.A.First.rewind
               (i32.const 0)
               (global.set $SilverOrb.ArenaTest.A.First.bump_offset)
           """

    assert A.to_wat() =~ ~s"""
             (func $SilverOrb.ArenaTest.A.Second.rewind
               (i32.const #{2 * Orb.Memory.page_byte_size()})
               (global.set $SilverOrb.ArenaTest.A.Second.bump_offset)
           """

    assert A.to_wat() =~ ~S"""
             (func $test (export "test") (result i32 i32 i32 i32)
               (call $SilverOrb.ArenaTest.A.First.alloc! (i32.const 16))
               (call $SilverOrb.ArenaTest.A.First.alloc! (i32.const 16))
               (call $SilverOrb.ArenaTest.A.Second.alloc! (i32.const 16))
               (call $SilverOrb.ArenaTest.A.First.rewind)
               (call $SilverOrb.ArenaTest.A.First.alloc! (i32.const 16))
             )
           """
  end

  @moduletag wat: Orb.to_wat(A)

  test "documented example works", %{call_function: call_function} do
    # IO.puts(A.to_wat())
    {:ok, result} = call_function.(:example, [])
    assert result == []
  end

  test "allocates separate memory offsets", %{call_function: call_function} do
    # IO.puts(A.to_wat())
    {:ok, result} = call_function.(:test, [])
    assert result === [0, 16, 131_072, 0]
  end

  test "just enough allocations", %{call_function: call_function} do
    {:ok, [result]} = call_function.(:just_enough, [])
    assert 131_056 = result
  end

  test "too many allocations", %{call_function: call_function} do
    assert {:error, _} = call_function.(:too_many, [])
  end

  test "within max pages", %{call_function: call_function, write_binary: write_binary} do
    assert 8 = A.Third.Values.end_page_offset()
    assert 10 = A.Third.Values.max_end_page_offset()
    assert {:ok, [8]} = call_function.(:memory_page_count, [])
    assert {:ok, [589_824]} = call_function.(:within_max_pages, [])
    assert 589_824 = 9 * 64 * 1024
    assert {:ok, [10]} = call_function.(:memory_page_count, [])

    # Write binary values to specific memory locations
    write_binary.(6 * 64 * 1024, <<0x78, 0x56, 0x34, 0x12>>)
    write_binary.(8 * 64 * 1024, <<0x78, 0x56, 0x34, 0x12>>)
    write_binary.(9 * 64 * 1024, <<0x34, 0x12>>)
    write_binary.(10 * 64 * 1024 - 4, <<0x78, 0x56, 0x34, 0x12>>)

    # These would cause errors in the original code
    # write_binary.(10 * 64 * 1024 - 3, <<0x78, 0x56, 0x34, 0x12>>)
    # write_binary.(10 * 64 * 1024, <<0x78, 0x56, 0x34, 0x12>>)
    # write_binary.(13 * 64 * 1024, <<0x78, 0x56, 0x34, 0x12>>)
  end

  test "over max pages", %{call_function: call_function} do
    assert {:error, _} = call_function.(:over_max_pages, [])
  end

  defmodule UnsafePointerTypeModule do
    use Orb
    alias require SilverOrb.Arena

    Arena.def(Heap, pages: 2)

    defw accept_ptr(p1: Heap.UnsafePointer) do
      Heap.UnsafePointer.validate!(p1)
    end
  end

  test "child UnsafePointer type maps to i32" do
    # Code.ensure_loaded!(UnsafePointerTypeModule.Heap)
    # Code.ensure_loaded!(UnsafePointerTypeModule.Heap.UnsafePointer)
    assert UnsafePointerTypeModule.to_wat() =~ ~S|(param $p1 i32)|
  end

  test "UnsafePointer.memory_range/0" do
    alias UnsafePointerTypeModule.Heap.UnsafePointer

    assert 0 in UnsafePointer.memory_range()
    assert 0xFF in UnsafePointer.memory_range()
    assert (2 * 64 * 1024) in UnsafePointer.memory_range()
    assert (2 * 64 * 1024 + 1) not in UnsafePointer.memory_range()
    assert 0xFFFFFF not in UnsafePointer.memory_range()
    assert 0..(2 * 64 * 1024) === UnsafePointer.memory_range()
  end

  test "UnsafePointer.validate!/1" do
    wat = Orb.to_wat(UnsafePointerTypeModule)
    {:ok, pid} = Wasmex.start_link(%{bytes: wat})
    call_function = &Wasmex.call_function(pid, &1, &2)

    assert {:ok, []} = call_function.(:accept_ptr, [0])
    assert {:ok, []} = call_function.(:accept_ptr, [2 * 64 * 1024])
    assert {:error, _} = call_function.(:accept_ptr, [2 * 64 * 1024 + 1])
    assert {:error, _} = call_function.(:accept_ptr, [0xFFFFFF])
  end

  test "child String type maps to i64" do
    defmodule StringType do
      use Orb
      alias require SilverOrb.Arena

      Arena.def(Heap, pages: 2)

      defw accept_string(s1: Heap.String) do
      end
    end

    # Code.ensure_loaded!(StringType.Heap)
    # Code.ensure_loaded!(StringType.Heap.String)
    assert StringType.to_wat() =~ ~S|(param $s1 i64)|
  end

  test "Created arena module has a string_equal?/1 function" do
    defmodule EqualToString do
      use Orb
      alias require SilverOrb.Arena

      Arena.def(Input, pages: 1)

      defw(input_offset(), I32, do: Input.Values.start_page_offset() * Memory.page_byte_size())

      defw equal_test(), {I32, I32, I32, I32} do
        {
          Input.string_equal?("abc"),
          Input.string_equal?("mn"),
          Input.string_equal?("mno"),
          Input.string_equal?("mnop")
        }
      end

      defw match_test(), I32 do
        Arena.match_string Input, I32 do
          "abc" -> i32(1)
          "mn" -> i32(2)
          "mno" -> i32(3)
          "mnop" -> i32(4)
        end
      end
    end

    wat = Orb.to_wat(EqualToString)
    {:ok, pid} = Wasmex.start_link(%{bytes: wat})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)

    call_function = &Wasmex.call_function(pid, &1, &2)
    write_binary = &Wasmex.Memory.write_binary(store, memory, &1, &2)

    {:ok, [input_ptr]} = call_function.(:input_offset, [])

    # Write "mno" to memory
    write_binary.(input_ptr, "mno")

    {:ok, result} = call_function.(:equal_test, [])
    assert [0, 0, 1, 0] = result

    {:ok, [match_result]} = call_function.(:match_test, [])
    assert 3 = match_result
  end
end
