defmodule IntFormatterTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  setup do
    wat = Orb.to_wat(SilverOrb.IntFormatter)
    instance = Instance.run(wat)

    wasm_decimal_u32 = fn n when is_integer(n) ->
      input_ptr = Orb.Memory.page_byte_size()

      {ptr, len} = Instance.call(instance, :decimal_u32, n, input_ptr)
      str = Instance.read_memory(instance, ptr, len)
      str
    end

    %{instance: instance, wasm_decimal_u32: wasm_decimal_u32}
  end

  describe "IntFormatter" do
    test "decimal_u32_char_count", %{instance: i} do
      assert Instance.call(i, :decimal_u32_char_count, 0) == 1
      assert Instance.call(i, :decimal_u32_char_count, 7) == 1
      assert Instance.call(i, :decimal_u32_char_count, 17) == 2
      assert Instance.call(i, :decimal_u32_char_count, 173) == 3
      assert Instance.call(i, :decimal_u32_char_count, 604_800) == 6
    end

    test "decimal_u32", %{wasm_decimal_u32: wasm_decimal_u32} do
      assert wasm_decimal_u32.(0) == "0"
      assert wasm_decimal_u32.(7) == "7"
      assert wasm_decimal_u32.(17) == "17"
      assert wasm_decimal_u32.(173) == "173"
      assert wasm_decimal_u32.(604_800) == "604800"
      assert wasm_decimal_u32.(0xFFFF_FFFF) == "4294967295"
    end
  end
end
