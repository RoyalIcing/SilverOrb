defmodule URITest do
  use WasmexCase, async: true
  alias SilverOrb.URI.URIParseResult, as: Result

  @moduletag wat: Orb.to_wat(SilverOrb.URI)

  setup %{uri_string: uri_string, call_function: call_function, write_binary: write_binary} do
    write_binary.(0x100, uri_string)

    assert {:ok, values} = call_function.("parse", [0x100, byte_size(uri_string)])
    result = Result.from_values(values)
    %{result: result}
  end

  @tag uri_string: "mailto:"
  test "parse mailto:", %{result: result} do
    assert result.flags == 0x1
    assert result.scheme == {0x100, 6}
  end

  @tag uri_string: "http:"
  test "parse http:", %{result: result} do
    assert result.flags == 0x1
    assert result.scheme == {0x100, 4}
  end

  @tag uri_string: "tel:+1-816-555-1212"
  test "parse tel:+1-816-555-1212", %{result: result} do
    assert result.flags == 0x1
    assert result.scheme == {0x100, 3}
  end
end
