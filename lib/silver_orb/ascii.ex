defmodule SilverOrb.ASCII do
  use Orb

  defw uppercase8(i: I32.U8), I32.U8 do
    # TODO
  end

  defw uppercase32(i: I32), I32 do
    # Magic transformation to convert 4 characters at once
  end

  defw uppercase64(i: I64), I64 do
    # Magic transformation to convert 8 characters at once
  end

  defw uppercase(range: Memory.Slice) do
    # Memory.Slice.update64(&uppercase64/1)
    # Memory.Slice.update(range, &uppercase8/1, i64: &uppercase64/1)
  end

  defw lowercase(range: Memory.Slice) do
    # TODO
  end
end
