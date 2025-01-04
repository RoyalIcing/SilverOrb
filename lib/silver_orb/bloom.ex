defmodule SilverOrb.Bloom do
  defmodule Bloom64 do
    use Orb

    def wasm_type(), do: :i64

    defw insert(table: Bloom64, hash: I64), Bloom64 do
      I64.or(table, hash)
    end

    defw contains?(table: Bloom64, hash: I64), I32 do
      I64.band(table, hash) === hash
    end
  end
end
