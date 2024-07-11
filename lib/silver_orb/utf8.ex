defmodule SilverOrb.UTF8 do
  use Orb

  Memory.pages(2)

  # defw valid?(str_ptr: Str.Pointer, str_len: Str.Length), I32 do
  defw valid?(str_ptr: I32.UnsafePointer, str_len: I32), I32,
    i: I32,
    byte0: I32.U8,
    byte1: I32.U8,
    byte2: I32.U8,
    byte3: I32.U8 do
    loop Validate do
      if i === str_len do
        return(1)
      end

      if i > str_len do
        return(0)
      end

      byte0 = Memory.load!(I32.U8, str_ptr + i)

      I32.cond do
        # 0xxxxxxx
        I32.band(byte0, 0x80) === 0x00 ->
          i = i + 1
          Validate.continue()

        # 110xxxxx 10xxxxxx
        I32.band(byte0, 0xE0) === 0xC0 ->
          if i + 1 >= str_len do
            return(0)
          end

          # Check for overlong encoding
          if byte0 === 0xC0 or byte0 === 0xC1 do
            return(0)
          end

          byte1 = Memory.load!(I32.U8, str_ptr + i + 1)

          unless I32.band(byte1, 0xC0) === 0x80 do
            return(0)
          end

          i = I32.add(i, 2)
          Validate.continue()

        # 1110xxxx 10xxxxxx 10xxxxxx
        I32.band(byte0, 0xF0) === 0xE0 ->
          if i + 2 >= str_len do
            return(0)
          end

          byte1 = Memory.load!(I32.U8, str_ptr + i + 1)
          byte2 = Memory.load!(I32.U8, str_ptr + i + 2)

          # Check for overlong encoding and surrogates
          if (byte0 === 0xE0 &&& I32.band(byte1, 0xE0) === 0x80) or
               (byte0 === 0xED &&& I32.band(byte1, 0xE0) === 0xA0) do
            return(0)
          end

          unless I32.band(byte1, 0xC0) === 0x80 &&& I32.band(byte2, 0xC0) === 0x80 do
            return(0)
          end

          i = I32.add(i, 3)
          Validate.continue()

        # 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        I32.band(byte0, 0xF8) === 0xF0 ->
          unless I32.add(i, 3) < str_len do
            return(0)
          end

          byte1 = Memory.load!(I32.U8, str_ptr + i + 1)
          byte2 = Memory.load!(I32.U8, str_ptr + i + 2)
          byte3 = Memory.load!(I32.U8, str_ptr + i + 3)

          # Check for overlong encoding
          # if byte0 === 0xF0 &&& I32.band(byte1, 0xF0) === 0x80 do
          #   return(0)
          # end

          # Check for overlong encoding
          if (byte0 === 0xF0 &&& I32.lt_u(I32.band(byte1, 0xF0), 0x90)) or
               (byte0 === 0xF4 &&& I32.gt_u(I32.band(byte1, 0xF0), 0x8F)) do
            return(0)
          end

          unless I32.band(byte1, 0xC0) === 0x80 &&&
                   I32.band(byte2, 0xC0) === 0x80 &&&
                   I32.band(byte3, 0xC0) === 0x80 do
            return(0)
          end

          i = I32.add(i, 4)
          Validate.continue()

        # Invalid UTF-8 byte
        true ->
          return(0)
      end

      Validate.continue()
    end

    1
  end
end
