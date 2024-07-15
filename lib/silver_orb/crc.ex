defmodule SilverOrb.CRC do
  # See http://www.ross.net/crc/download/crc_v3.txt

  @moduledoc """
  Calculate CRC (Cyclic Redundancy Check) checksums, used in various file formats (e.g. PNG, Gzip) and network communication.
  """
  use Orb

  # Used for testing
  Memory.pages(2)

  @doc """
  Calculate CRC32 (IEEE 802.3) checksum.

  https://www.w3.org/TR/png/#D-CRCAppendix
  """
  defw crc32(ptr: I32.UnsafePointer, len: I32), I32, i: I32, c: I32 do
    if len === 0, do: return(0)

    c = 0xFFFFFFFF

    loop EachByte do
      c = c |> I32.xor(Memory.load!(I32.U8, ptr + i))

      c = if(c &&& 1, do: I32.xor(I32.shr_u(c, 1), 0xEDB88320), else: I32.shr_u(c, 1))
      c = if(c &&& 1, do: I32.xor(I32.shr_u(c, 1), 0xEDB88320), else: I32.shr_u(c, 1))
      c = if(c &&& 1, do: I32.xor(I32.shr_u(c, 1), 0xEDB88320), else: I32.shr_u(c, 1))
      c = if(c &&& 1, do: I32.xor(I32.shr_u(c, 1), 0xEDB88320), else: I32.shr_u(c, 1))
      c = if(c &&& 1, do: I32.xor(I32.shr_u(c, 1), 0xEDB88320), else: I32.shr_u(c, 1))
      c = if(c &&& 1, do: I32.xor(I32.shr_u(c, 1), 0xEDB88320), else: I32.shr_u(c, 1))
      c = if(c &&& 1, do: I32.xor(I32.shr_u(c, 1), 0xEDB88320), else: I32.shr_u(c, 1))
      c = if(c &&& 1, do: I32.xor(I32.shr_u(c, 1), 0xEDB88320), else: I32.shr_u(c, 1))

      i = i + 1

      if i < len do
        EachByte.continue()
      end
    end

    I32.xor(c, 0xFFFFFFFF)
  end
end
