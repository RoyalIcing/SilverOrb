defmodule IntFormatterTest do
  use WasmexCase, async: true
  import WasmexCase.Helper

  @moduletag wat: Orb.to_wat(SilverOrb.IntFormatter)

  setup %{call_function: call_function, read_binary: read_binary} do
    wasm_decimal_u32 = fn n when is_integer(n) ->
      input_ptr = 0x400

      {:ok, [ptr, len]} = call_function.(:decimal_u32, [n, input_ptr])
      read_binary.(ptr, len)
    end

    %{wasm_decimal_u32: wasm_decimal_u32}
  end

  describe "IntFormatter" do
    test "decimal_u32_char_count", %{call_function: call_function} do
      assert {:ok, [1]} = call_function.(:decimal_u32_char_count, [0])
      assert {:ok, [1]} = call_function.(:decimal_u32_char_count, [7])
      assert {:ok, [2]} = call_function.(:decimal_u32_char_count, [17])
      assert {:ok, [3]} = call_function.(:decimal_u32_char_count, [173])
      assert {:ok, [6]} = call_function.(:decimal_u32_char_count, [604_800])
    end

    test "decimal_u32", %{wasm_decimal_u32: wasm_decimal_u32} do
      assert wasm_decimal_u32.(0) == "0"
      assert wasm_decimal_u32.(7) == "7"
      assert wasm_decimal_u32.(17) == "17"
      assert wasm_decimal_u32.(173) == "173"
      assert wasm_decimal_u32.(604_800) == "604800"
      assert wasm_decimal_u32.(u32_to_s32(0xFFFF_FFFF)) == "4294967295"
    end
  end
end
