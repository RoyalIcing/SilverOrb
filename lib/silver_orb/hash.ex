defmodule SilverOrb.Hash do
  # See http://www.cse.yorku.ca/~oz/hash.html
  # https://en.wikipedia.org/wiki/Fowler–Noll–Vo_hash_function
  # https://en.wikipedia.org/wiki/SipHash

  @moduledoc """
  Calculate hashes on a range of memory.
  """
  use Orb

  # Used for testing
  Memory.pages(2)

  @doc """
  Calculate Daniel J. Bernstein’s hash.

  http://www.cse.yorku.ca/~oz/hash.html
  """
  defw djb2(ptr: I32.UnsafePointer, len: I32), I32, i: I32, hash: I32 do
    if len === 0, do: return(5381)

    hash = 5381

    loop EachByte do
      hash = (hash <<< 5) + hash + Memory.load!(I32.U8, ptr + i)
      # hash = (hash <<< 5) + hash + ptr[u8: i]
      # hash = (hash <<< 5) + hash + ptr[i].u8

      i = i + 1

      if i < len do
        EachByte.continue()
      end
    end

    hash
  end

  # TODO: fnv1a https://github.com/ziglang/zig/blob/ce5a5c361b5b098c3b7d68f88136a9c91e7bec19/lib/std/hash/fnv.zig
  # defw fnv1a32(ptr: I32.UnsafePointer, len: I32), I32
  # defw fnv1a64(ptr: I32.UnsafePointer, len: I32), I64
end
