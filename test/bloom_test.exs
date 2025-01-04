defmodule BloomTest do
  use ExUnit.Case, async: true

  describe "Bloom64" do
    setup do
      wat = Orb.to_wat(SilverOrb.Bloom.Bloom64)
      %{wat: wat}
    end

    defp expect_0({:ok, []}), do: nil
    defp expect_1({:ok, [value]}), do: value
    defp expect_2({:ok, [first, second]}), do: {first, second}

    setup %{wat: wat} do
      {:ok, pid} = Wasmex.start_link(%{bytes: wat})
      {:ok, store} = Wasmex.store(pid)

      call = %{
        insert: &expect_1(Wasmex.call_function(pid, "insert", [&1, &2])),
        contains?: &expect_1(Wasmex.call_function(pid, "contains?", [&1, &2]))
      }

      %{pid: pid, store: store, call: call}
    end

    defp hash(term) do
      # :erlang.crc32(term)
      :erlang.phash2(term)
    end
    
    defp insert_term(call, table, term) do
      hash = hash(term)
      call.insert.(table, hash)
    end
    
    defp contains_term?(call, table, term) do
      hash = hash(term)
      1 === call.contains?.(table, hash)
    end

    test "erlang hashes", %{call: call} do
      table =
        for string <- ["a", "b", "c", "d"], reduce: 0 do
          table ->
            insert_term(call, table, string)
        end
      
      assert contains_term?(call, table, "a")
      assert contains_term?(call, table, "b")
      assert contains_term?(call, table, "c")
      assert contains_term?(call, table, "d")
      
      refute contains_term?(call, table, "hello!!")
      refute contains_term?(call, table, "z")
      refute contains_term?(call, table, "1234")
    end
  end
end
