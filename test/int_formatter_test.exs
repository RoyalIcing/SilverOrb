defmodule IntFormatterTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Wasm
  alias SilverOrb.IntFormatter

  describe "IntFormatter" do
    test "format_u32_char_count" do
      assert Wasm.call(IntFormatter, :format_u32_char_count, 0) == 1
      assert Wasm.call(IntFormatter, :format_u32_char_count, 7) == 1
      assert Wasm.call(IntFormatter, :format_u32_char_count, 17) == 2
      assert Wasm.call(IntFormatter, :format_u32_char_count, 173) == 3
      assert Wasm.call(IntFormatter, :format_u32_char_count, 604_800) == 6
    end
  end
end
