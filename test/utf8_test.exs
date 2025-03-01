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
      context.write_binary.(input_ptr, s <> <<0>>)
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

  def length_control(string, write_and_call) do
    elixir_length = String.length(string)
    assert {:ok, [wasm_length]} = write_and_call.(string, :length)
    assert {string, elixir_length} === {string, wasm_length}
    wasm_length
  end

  test "length/1", %{write_and_call: write_and_call} do
    assert {:ok, [3]} = write_and_call.("abc", :length)
    assert {:ok, [5]} = write_and_call.("եոգլի", :length)

    latin_e_with_acute = "é"
    assert 2 = byte_size(latin_e_with_acute)
    assert 1 = String.length(latin_e_with_acute)
    assert {:ok, [1]} = write_and_call.(latin_e_with_acute, :length)

    # Test word with combining marks
    # A with macron and grave accent
    combining_mark_example = "Ā̀stute"
    assert 9 = byte_size(combining_mark_example)
    assert 6 = String.length(combining_mark_example)
    assert {:ok, [6]} = write_and_call.(combining_mark_example, :length)

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

    # Testing complex emoji sequence with Zero-Width Joiners
    face_palm_emoji = "🤦🏼‍♂️"
    assert 17 = byte_size(face_palm_emoji)
    assert 1 = String.length(face_palm_emoji)
    assert {:ok, [1]} = write_and_call.(face_palm_emoji, :length)

    # Testing flag emoji (regional indicators)
    # US flag
    flag_emoji = "🇺🇸"
    assert 8 = byte_size(flag_emoji)
    assert 1 = String.length(flag_emoji)
    assert {:ok, [1]} = write_and_call.(flag_emoji, :length)

    assert length_control("elixir", write_and_call) == 6
    assert length_control("elixrí", write_and_call) == 6
    assert length_control("եոգլից", write_and_call) == 6
    assert length_control("ліксрэ", write_and_call) == 6
    assert length_control("ειξήριολ", write_and_call) == 8
    assert length_control("סם ייםח", write_and_call) == 7
    assert length_control("がガちゃ", write_and_call) == 4
    assert length_control("Ā̀stute", write_and_call) == 6
    assert length_control("👨‍👩‍👧‍👦", write_and_call) == 1
    assert length_control("👨‍⚕️", write_and_call) == 1
    assert length_control("👩‍🚀", write_and_call) == 1
    assert length_control("", write_and_call) == 0
  end

  def code_point_count_control(string, write_and_call) do
    elixir_count = String.codepoints(string) |> length()
    assert {:ok, [wasm_count]} = write_and_call.(string, :code_point_count)
    assert {string, elixir_count} === {string, wasm_count}
    wasm_count
  end

  test "code_point_count/1", %{write_and_call: write_and_call} do
    # Simple ASCII string
    assert {:ok, [3]} = write_and_call.("abc", :code_point_count)

    # UTF-8 multi-byte characters
    assert {:ok, [5]} = write_and_call.("եոգլի", :code_point_count)

    # Latin e with acute accent (precomposed, single code point)
    # U+00E9
    latin_e_with_acute_precomposed = "é"
    assert 2 = byte_size(latin_e_with_acute_precomposed)
    assert 1 = code_point_count_control(latin_e_with_acute_precomposed, write_and_call)

    # Latin e with acute accent (decomposed, two code points)
    # U+0065 + U+0301
    latin_e_with_acute_decomposed = "e\u0301"
    assert 3 = byte_size(latin_e_with_acute_decomposed)
    assert 2 = code_point_count_control(latin_e_with_acute_decomposed, write_and_call)

    # Test word with combining marks
    # 'A' with macron and grave accent + "stute"
    combining_mark_example = "Ā̀stute"
    assert 9 = byte_size(combining_mark_example)
    assert 7 = code_point_count_control(combining_mark_example, write_and_call)

    # Simple emoji (single code point)
    simple_emoji = "😀"
    assert 4 = byte_size(simple_emoji)
    assert 1 = code_point_count_control(simple_emoji, write_and_call)

    # Emoji with skin tone modifier (two code points)
    emoji_with_modifier = "👍🏼"
    assert 8 = byte_size(emoji_with_modifier)
    assert 2 = code_point_count_control(emoji_with_modifier, write_and_call)

    # Face palm emoji (multiple code points)
    # Person facepalming + skin tone + ZWJ + male sign + VS
    face_palm_emoji = "🤦🏼‍♂️"
    assert 17 = byte_size(face_palm_emoji)
    assert 5 = code_point_count_control(face_palm_emoji, write_and_call)

    # Flag emoji (two code points for regional indicators)
    # US flag
    flag_emoji = "🇺🇸"
    assert 8 = byte_size(flag_emoji)
    assert 2 = code_point_count_control(flag_emoji, write_and_call)

    # Family emoji (multiple code points with ZWJs)
    # Man + ZWJ + Woman + ZWJ + Girl + ZWJ + Boy
    family_emoji = "👨‍👩‍👧‍👦"
    assert 25 = byte_size(family_emoji)
    assert 7 = code_point_count_control(family_emoji, write_and_call)

    # Doctor emoji (profession emoji with ZWJ)
    # Man + ZWJ + Medical Symbol + VS16
    doctor_emoji = "👨‍⚕️"
    assert 13 = byte_size(doctor_emoji)
    assert 4 = code_point_count_control(doctor_emoji, write_and_call)

    # Astronaut emoji (profession emoji with ZWJ)
    # Woman + ZWJ + Rocket
    astronaut_emoji = "👩‍🚀"
    assert 11 = byte_size(astronaut_emoji)
    assert 3 = code_point_count_control(astronaut_emoji, write_and_call)

    # Empty string
    assert {:ok, [0]} = write_and_call.("", :code_point_count)
  end
end
