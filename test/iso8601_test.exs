defmodule ISO8601Test do
  use WasmexCase, async: true

  @moduletag wat: Orb.to_wat(SilverOrb.ISO8601)

  describe "parse_date" do
    setup %{write_binary: write_binary, call_function: call_function} do
      write_and_parse = fn input ->
        write_binary.(0x100, input)
        assert {:ok, result} = call_function.(:parse_date, [0x100, byte_size(input)])
        result
      end

      %{write_and_parse: write_and_parse}
    end

    test "invalid dates return zero", %{write_and_parse: write_and_parse} do
      assert write_and_parse.("") == [0, 0, 0]
      assert write_and_parse.("abc") == [0, 0, 0]
      assert write_and_parse.("2030-08-1") == [0, 0, 0]
      assert write_and_parse.("2030-08-111") == [0, 0, 0]
      assert write_and_parse.("2030-08-011") == [0, 0, 0]
      assert write_and_parse.("2030:08-19") == [0, 0, 0]
    end

    test "days in month are checked", %{write_and_parse: write_and_parse} do
      assert write_and_parse.("1900-02-29") == [0, 0, 0]
      assert write_and_parse.("2000-02-30") == [0, 0, 0]
      assert write_and_parse.("2001-02-29") == [0, 0, 0]

      assert write_and_parse.("2005-05-31") == [0, 0, 0]
    end

    test "valid dates parse correctly", %{write_and_parse: write_and_parse} do
      assert write_and_parse.("2030-08-19") == [2030, 8, 19]
      assert write_and_parse.("2030-12-19") == [2030, 12, 19]
      assert write_and_parse.("2030-12-01") == [2030, 12, 1]
      assert write_and_parse.("1000-12-01") == [1000, 12, 1]
      assert write_and_parse.("0000-12-01") == [0, 12, 1]

      assert write_and_parse.("2005-05-30") == [2005, 5, 30]

      assert write_and_parse.("2000-02-29") == [2000, 2, 29]
      assert write_and_parse.("2001-02-28") == [2001, 2, 28]
    end
  end

  describe "parse_time" do
    setup %{write_binary: write_binary, call_function: call_function} do
      write_and_parse = fn input ->
        write_binary.(0x100, String.duplicate("\0", 50))
        write_binary.(0x100, input)
        assert {:ok, result} = call_function.(:parse_time, [0x100, byte_size(input)])
        result
      end

      %{write_and_parse: write_and_parse}
    end

    test "invalid times return zero", %{write_and_parse: write_and_parse} do
      assert write_and_parse.("") == [-1, 0, 0, 0]
      assert write_and_parse.("abc") == [-1, 0, 0, 0]

      assert write_and_parse.("23:50:61") == [-1, 0, 0, 0]
      assert write_and_parse.("23:50:60") == [-1, 0, 0, 0]
      assert write_and_parse.("24:00:00") == [-1, 0, 0, 0]

      assert write_and_parse.("12:34:56A") == [-1, 0, 0, 0]
      assert write_and_parse.("12:34:56.789123A") == [-1, 0, 0, 0]
      assert write_and_parse.("12:34:56.789A") == [-1, 0, 0, 0]
    end

    test "valid times parse correctly", %{write_and_parse: write_and_parse} do
      assert write_and_parse.("12:34:56") == [12, 34, 56, 0]
      assert write_and_parse.("23:50:07") == [23, 50, 7, 0]
      assert write_and_parse.("00:14:55") == [0, 14, 55, 0]
      assert write_and_parse.("00:00:00") == [0, 0, 0, 0]

      assert write_and_parse.("12:34:56.789123") == [12, 34, 56, 789_123]
      assert write_and_parse.("12:34:56.789") == [12, 34, 56, 789_000]
      assert write_and_parse.("12:34:56.7") == [12, 34, 56, 700_000]
      assert write_and_parse.("12:34:56.0") == [12, 34, 56, 0]
      # assert write_and_parse.("12:34:56.789123567") == [12, 34, 56, 789123]

      assert write_and_parse.("T23:50:07") == [23, 50, 7, 0]
    end
  end

  describe "format_date" do
    setup %{read_binary: read_binary, call_function: call_function} do
      format_and_read = fn year, month, day ->
        assert {:ok, [ptr, size]} = call_function.(:format_date, [year, month, day, 0x100, 0x40])
        read_binary.(ptr, size)
      end

      %{format_and_read: format_and_read}
    end

    test "valid dates format correctly", %{format_and_read: format_and_read} do
      assert format_and_read.(2030, 8, 19) == "2030-08-19"
      assert format_and_read.(2134, 8, 19) == "2134-08-19"
      assert format_and_read.(2030, 12, 19) == "2030-12-19"
      assert format_and_read.(2030, 12, 1) == "2030-12-01"
      assert format_and_read.(1000, 12, 1) == "1000-12-01"
      assert format_and_read.(0, 12, 1) == "0000-12-01"
      assert format_and_read.(2005, 5, 30) == "2005-05-30"
      assert format_and_read.(2000, 2, 29) == "2000-02-29"
      assert format_and_read.(2001, 2, 28) == "2001-02-28"
      assert format_and_read.(1, 1, 1) == "0001-01-01"
      assert format_and_read.(0, 1, 1) == "0000-01-01"
    end

    test "invalid dates return empty string", %{format_and_read: format_and_read} do
      assert format_and_read.(2000, 0, 1) == ""
      assert format_and_read.(2000, 1, 0) == ""
      assert format_and_read.(10000, 1, 1) == ""
    end
  end

  describe "format_time" do
    setup %{read_binary: read_binary, call_function: call_function} do
      format_and_read = fn hours, minutes, seconds, microseconds ->
        assert {:ok, [ptr, size]} =
                 call_function.(:format_time, [hours, minutes, seconds, microseconds, 0x100, 0x40])

        read_binary.(ptr, size)
      end

      %{format_and_read: format_and_read}
    end

    test "valid times format correctly", %{format_and_read: format_and_read} do
      assert format_and_read.(17, 38, 29, 0) == "17:38:29"
      assert format_and_read.(0, 38, 29, 0) == "00:38:29"
      assert format_and_read.(0, 0, 0, 0) == "00:00:00"
      assert format_and_read.(17, 38, 29, 123_456) == "17:38:29.123456"
      assert format_and_read.(17, 38, 29, 123_456) == "17:38:29.123456"
      assert format_and_read.(17, 38, 29, 987_654) == "17:38:29.987654"
    end

    test "invalid times return empty string", %{format_and_read: format_and_read} do
      assert format_and_read.(60, 0, 0, 0) == ""
    end
  end
end
