defmodule SilverOrb.Log do
  use Orb.Import, name: :log

  defmacro __using__(_opts) do
    quote do
      alias unquote(__MODULE__)

      Orb.Import.register(Log)
    end
  end

  defw(u32(u: I32))
  defw(u64(u: I64))
  defw(utf8(ptr: I32.UnsafePointer, size: I32))
  defw(bytes(ptr: I32.UnsafePointer, size: I32))

  def four_cc(binary) when is_binary(binary) and byte_size(binary) == 4 do
    four_cc(I32.from_4_byte_ascii(binary))
  end

  defw(four_cc(four_cc: I32))

  defw(putc(utf8char: I32))

  def puts(string, extra \\ :newline)

  def puts(<<utf8char::utf8, rest::binary>>, extra) do
    Orb.snippet do
      putc(utf8char)
      puts(rest, extra)
    end
  end

  def puts("", :newline), do: putc(?\n)

  def puts("", [{:u32, u} | extra]) do
    Orb.snippet do
      u32(u)
      # putc(?;)
      # putc(0x20)
      puts("", extra)
    end
  end

  def puts("", [{:newline, true} | extra]) do
    Orb.snippet do
      putc(?\n)
      puts("", extra)
    end
  end

  def puts("", []), do: Orb.InstructionSequence.empty()

  # def print(string, extra \\ [])
  # def print(string, extra) when is_binary(string) do
  #   Orb.snippet do
  #     utf8(Memory.Slice.get_byte_offset(Str.to_slice(string)), byte_size(string))
  #     utf8(Memory.Slice.get_byte_offset(Str.to_slice(extra)), byte_size(extra))
  #   end
  # end

  def utf8_slice(slice) do
    utf8(Memory.Slice.get_byte_offset(slice), Memory.Slice.get_byte_length(slice))
  end

  def str(str) do
    utf8_slice(Str.to_slice(str))
  end
end
