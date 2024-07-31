defmodule SortTest do
  use ExUnit.Case, async: true
  @moduletag timeout: 1000

  defmodule SortIntegers do
    use Orb

    # TODO: open https://github.com/RoyalIcing/Orb/issues
    # Memory.pages 2 do
    #   data 0xFF, i32: [4, 9, 3]
    #   0xFF -> [i32(4), i32(9), i32(3)]
    # end

    Memory.pages(1)

    # data I32, 0xff,
    # data i32: [0xff, 0x01]
    # I32.data 0xff, [0xff, 0x01]
    # I32.U8.data 0xff, [0xff, 0x01]
    # Bytes.data 0xff, [0xff, 0x01]
    Memory.initial_data!(0x400, u32: [4, 9, 3, 12, 2])

    # Memory.initial_data(I32.U8, %{
    #   0xFF => [7, 4, 3]
    # })

    defw bubble_sort() do
      SilverOrb.Sort.bubble_sort(
        count: 5,
        read_at: fn index ->
          Memory.load!(I32, I32.add(0x400, I32.mul(4, index)), align: 4)
        end,
        swap_at_with_next: fn index ->
          a = I32.add(0x400, I32.mul(4, index))
          b = I32.add(0x400, I32.mul(4, I32.add(index, 1)))

          Memory.swap!(I32, a, b, align: 4)
        end,
        calc_gt: &I32.ge_u/2
      )
    end

    defw read_item(index: I32), I32 do
      Memory.load!(I32, 0x400 + 4 * index, align: 4)
    end
  end

  test "bubble_sort OrbWasmtime" do
    alias OrbWasmtime.Instance
    wat = Orb.to_wat(SortIntegers)
    instance = Instance.run(wat)

    assert 4 = Instance.call(instance, :read_item, 0)
    Instance.call(instance, :bubble_sort)
    assert 2 = Instance.call(instance, :read_item, 0)
    assert 3 = Instance.call(instance, :read_item, 1)
    assert 4 = Instance.call(instance, :read_item, 2)
    assert 9 = Instance.call(instance, :read_item, 3)
    assert 12 = Instance.call(instance, :read_item, 4)
  end

  test "bubble_sort Wasmex" do
    wat = Orb.to_wat(SortIntegers)
    {:ok, pid} = Wasmex.start_link(%{bytes: wat})

    assert {:ok, [4]} = Wasmex.call_function(pid, :read_item, [0])
    Wasmex.call_function(pid, :bubble_sort, [])
    assert {:ok, [2]} = Wasmex.call_function(pid, :read_item, [0])
    assert {:ok, [3]} = Wasmex.call_function(pid, :read_item, [1])
    assert {:ok, [4]} = Wasmex.call_function(pid, :read_item, [2])
    assert {:ok, [9]} = Wasmex.call_function(pid, :read_item, [3])
    assert {:ok, [12]} = Wasmex.call_function(pid, :read_item, [4])
  end
end
