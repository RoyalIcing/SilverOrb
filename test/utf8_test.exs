defmodule UTF8Test do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  test "valid?/2" do
    wat = Orb.to_wat(SilverOrb.UTF8)
    i = Instance.run(wat)

    assert 1 = check_valid?(i, "a")
    assert 1 = check_valid?(i, "abcde12345")
    assert 1 = check_valid?(i, "\x71")
    assert 1 = check_valid?(i, "\x75\x4c")
    assert 1 = check_valid?(i, "\xc3\xb1")
    assert 1 = check_valid?(i, "\xe2\x82\xa1")
    assert 1 = check_valid?(i, "\xf0\x90\x8c\xbc")
    assert 1 = check_valid?(i, "안녕하세요, 세상")
    assert 1 = check_valid?(i, "\xc2\x80")
    assert 1 = check_valid?(i, "\xf0\x90\x80\x80")
    assert 1 = check_valid?(i, "\xee\x80\x80")
    assert 1 = check_valid?(i, "\x7f\x4c\x23\x3c\x3a\x6f\x5d\x44\x13\x70")

    assert 0 = check_valid?(i, "\xc3\x28")
    assert 0 = check_valid?(i, "\xa0\xa1")
    assert 0 = check_valid?(i, "\xe2\x28\xa1")
    assert 0 = check_valid?(i, "\xe2\x82\x28")
    assert 0 = check_valid?(i, "\xf0\x28\x8c\xbc")
    assert 0 = check_valid?(i, "\xf0\x90\x28\xbc")
    assert 0 = check_valid?(i, "\xf0\x28\x8c\x28")
    assert 0 = check_valid?(i, "\xc0\x9f")
    assert 0 = check_valid?(i, "\xf5\xff\xff\xff")
    assert 0 = check_valid?(i, "\xed\xa0\x81")
    assert 0 = check_valid?(i, "\xf8\x90\x80\x80\x80")
    assert 0 = check_valid?(i, "123456789012345\xed")
    assert 0 = check_valid?(i, "123456789012345\xf1")
    assert 0 = check_valid?(i, "123456789012345\xc2")
    assert 0 = check_valid?(i, "\xC2\x7F")
    assert 0 = check_valid?(i, "\xce")
    assert 0 = check_valid?(i, "\xce\xba\xe1")
    assert 0 = check_valid?(i, "\xce\xba\xe1\xbd")
    assert 0 = check_valid?(i, "\xce\xba\xe1\xbd\xb9\xcf")
    assert 0 = check_valid?(i, "\xce\xba\xe1\xbd\xb9\xcf\x83\xce")
    assert 0 = check_valid?(i, "\xce\xba\xe1\xbd\xb9\xcf\x83\xce\xbc\xce")
    assert 0 = check_valid?(i, "\xdf")
    assert 0 = check_valid?(i, "\xef\xbf")
    assert 0 = check_valid?(i, "\x80")
    assert 0 = check_valid?(i, "\x91\x85\x95\x9e")
    assert 0 = check_valid?(i, "\x6c\x02\x8e\x18")

    # assert 0 =
    #          check_valid?(
    #            i,
    #            "\x25\x5b\x6e\x2c\x32\x2c\x5b\x5b\x33\x2c\x34\x2c\x05\x29\x2c\x33\x01\x01"
    #          )

    assert 0 = check_valid?(i, "\x80")
    assert 0 = check_valid?(i, "\x90")
    assert 0 = check_valid?(i, "\xa1")
    assert 0 = check_valid?(i, "\xb2")
    assert 0 = check_valid?(i, "\xc3")
    assert 0 = check_valid?(i, "\xd4")
    assert 0 = check_valid?(i, "\xe5")
    assert 0 = check_valid?(i, "\xf6")
    # assert 0 = check_valid?(i, "\xc3\xb1")
  end

  defp check_valid?(i, s) when is_binary(s) do
    input_ptr = Orb.Memory.page_byte_size()

    bytes = s |> :binary.bin_to_list()
    Instance.write_memory(i, input_ptr, bytes)

    Instance.call(i, :valid?, input_ptr, length(bytes))
  end
end
