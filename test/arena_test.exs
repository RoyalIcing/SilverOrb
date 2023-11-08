defmodule SilverOrb.ArenaTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  defmodule A do
    use Orb
    require alias SilverOrb.Arena

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

  test "documented example works" do
    # IO.puts(A.to_wat())
    i = Instance.run(A)
    f = Instance.capture(i, :example, 0)
    assert f.() === nil
  end

  test "allocates separate memory offsets" do
    # IO.puts(A.to_wat())
    i = Instance.run(A)
    f = Instance.capture(i, :test, 0)
    assert f.() === {0, 16, 131_072, 0}
  end

  test "just enough allocations" do
    i = Instance.run(A)
    f = Instance.capture(i, :just_enough, 0)
    assert 131_056 = f.()
  end

  test "too many allocations" do
    i = Instance.run(A)
    f = Instance.capture(i, :too_many, 0)
    assert {:error, _} = f.()
  end

  test "within max pages" do
    i = Instance.run(A)
    f = Instance.capture(i, :within_max_pages, 0)
    memory_page_count = Instance.capture(i, :memory_page_count, 0)
    assert 8 = A.Third.Values.end_page_offset()
    assert 10 = A.Third.Values.max_end_page_offset()
    assert 8 = memory_page_count.()
    assert 589_824 = f.()
    assert 589_824 = 9 * 64 * 1024
    assert 10 = memory_page_count.()

    assert {} = Instance.write_i32(i, 6 * 64 * 1024, 0x12345678)
    assert {} = Instance.write_i32(i, 8 * 64 * 1024, 0x12345678)
    assert {} = Instance.write_i32(i, 9 * 64 * 1024, 0x1234)
    assert {} = Instance.write_i32(i, 10 * 64 * 1024 - 4, 0x12345678)
    assert {:error, _} = Instance.write_i32(i, 10 * 64 * 1024 - 3, 0x12345678)
    assert {:error, _} = Instance.write_i32(i, 10 * 64 * 1024, 0x12345678)
    assert {:error, _} = Instance.write_i32(i, 13 * 64 * 1024, 0x12345678)
  end

  test "over max pages" do
    i = Instance.run(A)
    f = Instance.capture(i, :over_max_pages, 0)
    assert {:error, _} = f.()
  end
end
