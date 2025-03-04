defmodule ISO8601Test do
  # Code.require_file("wasmex_case.exs", __DIR__)
  # Code.require_file("wasmex_case.exs", __DIR__)
  use ExUnit.Case, async: true
  # use WasmexCase, async: true

  setup do
    wat = Orb.to_wat(SilverOrb.ISO8601)
    %{wat: wat}
  end

  setup %{wat: wat} do
    {:ok, pid} = Wasmex.start_link(%{bytes: wat})
    {:ok, memory} = Wasmex.memory(pid)
    {:ok, store} = Wasmex.store(pid)

    call_function = &Wasmex.call_function(pid, &1, &2)
    read_binary = &Wasmex.Memory.read_binary(store, memory, &1, &2)
    write_binary = &Wasmex.Memory.write_binary(store, memory, &1, &2)

    %{
      pid: pid,
      memory: memory,
      store: store,
      call_function: call_function,
      read_binary: read_binary,
      write_binary: write_binary
    }
  end

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
      
      assert write_and_parse.("12:34:56.789123") == [12, 34, 56, 789123]
      assert write_and_parse.("12:34:56.789") == [12, 34, 56, 789000]
      assert write_and_parse.("12:34:56.7") == [12, 34, 56, 700000]
      assert write_and_parse.("12:34:56.0") == [12, 34, 56, 0]
      # assert write_and_parse.("12:34:56.789123567") == [12, 34, 56, 789123]

      assert write_and_parse.("T23:50:07") == [23, 50, 7, 0]
    end
  end
end
