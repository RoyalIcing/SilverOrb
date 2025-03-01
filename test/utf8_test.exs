defmodule UTF8Test do
  use WasmexCase, async: true

  # No need for aliases, using WasmexCase

  @moduletag wat: Orb.to_wat(SilverOrb.UTF8)

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

  setup context do
    write_and_call = fn s, f ->
      input_ptr = Orb.Memory.page_byte_size()
      context.write_binary.(input_ptr, s)
      context.call_function.(f, [input_ptr, byte_size(s)])
    end

    %{write_and_call: write_and_call}
  end

  test "valid?/2", %{write_and_call: write_and_call} do
    Enum.each(@good_sequences, fn good_sequence ->
      assert {:ok, [1]} = write_and_call.(good_sequence, :valid?)
      assert String.valid?(good_sequence)
    end)

    Enum.each(@bad_sequences, fn bad_sequence ->
      assert {:ok, [0]} = write_and_call.(bad_sequence, :valid?)
      refute String.valid?(bad_sequence)
    end)

    # assert 0 =
    #          wasm_valid?(
    #            i,
    #            "\x25\x5b\x6e\x2c\x32\x2c\x5b\x5b\x33\x2c\x34\x2c\x05\x29\x2c\x33\x01\x01"
    #          )
    # assert 0 = wasm_valid?(i, "\xc3\xb1")
  end

  test "length/1", %{write_and_call: write_and_call} do
    assert {:ok, [3]} = write_and_call.("abc", :length)
    assert {:ok, [5]} = write_and_call.("եոգլի", :length)

    latin_e_with_acute = "é"
    assert 2 = byte_size(latin_e_with_acute)
    assert 1 = String.length(latin_e_with_acute)
    assert {:ok, [1]} = write_and_call.(latin_e_with_acute, :length)

    # Testing an emoji
    simple_emoji = "😀"
    assert 4 = byte_size(simple_emoji)
    assert 1 = String.length(simple_emoji)
    assert {:ok, [1]} = write_and_call.(simple_emoji, :length)
    
    # Testing emoji with skin tone modifier
    emoji_with_modifier = "👍🏼"
    assert 8 = byte_size(emoji_with_modifier)
    assert 1 = String.length(emoji_with_modifier)
    assert {:ok, [1]} = write_and_call.(emoji_with_modifier, :length)
    
    # Testing complex emoji sequence with ZWJ
    face_palm_emoji = "🤦🏼‍♂️"
    assert 17 = byte_size(face_palm_emoji)
    assert 1 = String.length(face_palm_emoji)
    assert {:ok, [1]} = write_and_call.(face_palm_emoji, :length)
  end
end
