defmodule UTF8Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  @good_sequences [
    "a",
    "abcde12345",
    "\x71",
    "\x75\x4c",
    "\xc3\xb1",
    "\xe2\x82\xa1",
    "\xf0\x90\x8c\xbc",
    "안녕하세요, 세상",
    "\xc2\x80",
    "\xf0\x90\x80\x80",
    "\xee\x80\x80",
    "\x7f\x4c\x23\x3c\x3a\x6f\x5d\x44\x13\x70"
  ]
  @bad_sequences [
    "\xc3\x28",
    "\xa0\xa1",
    "\xe2\x28\xa1",
    "\xe2\x82\x28",
    "\xf0\x28\x8c\xbc",
    "\xf0\x90\x28\xbc",
    "\xf0\x28\x8c\x28",
    "\xc0\x9f",
    "\xf5\xff\xff\xff",
    "\xed\xa0\x81",
    "\xf8\x90\x80\x80\x80",
    "123456789012345\xed",
    "123456789012345\xf1",
    "123456789012345\xc2",
    "\xC2\x7F",
    "\xce",
    "\xce\xba\xe1",
    "\xce\xba\xe1\xbd",
    "\xce\xba\xe1\xbd\xb9\xcf",
    "\xce\xba\xe1\xbd\xb9\xcf\x83\xce",
    "\xce\xba\xe1\xbd\xb9\xcf\x83\xce\xbc\xce",
    "\xdf",
    "\xef\xbf",
    "\x80",
    "\x91\x85\x95\x9e",
    "\x6c\x02\x8e\x18",
    "\x80",
    "\x90",
    "\xa1",
    "\xb2",
    "\xc3",
    "\xd4",
    "\xe5",
    "\xf6"
  ]

  test "valid?/2" do
    wat = Orb.to_wat(SilverOrb.UTF8)
    i = Instance.run(wat)

    Enum.each(@good_sequences, fn good_sequence ->
      assert 1 = wasm_valid?(i, good_sequence)
      assert String.valid?(good_sequence)
    end)

    Enum.each(@bad_sequences, fn bad_sequence ->
      assert 0 = wasm_valid?(i, bad_sequence)
      refute String.valid?(bad_sequence)
    end)

    # assert 0 =
    #          wasm_valid?(
    #            i,
    #            "\x25\x5b\x6e\x2c\x32\x2c\x5b\x5b\x33\x2c\x34\x2c\x05\x29\x2c\x33\x01\x01"
    #          )
    # assert 0 = wasm_valid?(i, "\xc3\xb1")
  end

  defp wasm_valid?(i, s) when is_binary(s) do
    input_ptr = Orb.Memory.page_byte_size()
    bytes = s |> :binary.bin_to_list()

    Instance.write_memory(i, input_ptr, bytes)
    Instance.call(i, :valid?, input_ptr, length(bytes))
  end
end
