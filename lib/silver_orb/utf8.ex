defmodule SilverOrb.UTF8 do
  use Orb

  # Used for testing
  Memory.pages(2)

  # TODO: double check against https://webassembly.github.io/spec/core/binary/values.html#binary-utf8
  # defw valid?(str_ptr: Str.Pointer, str_len: Str.Length), I32 do
  # defw valid?(str: Str), I32,
  defw valid?(str_ptr: I32.UnsafePointer, str_len: I32), I32,
    i: I32,
    byte0: I32.U8,
    byte1: I32.U8,
    byte2: I32.U8,
    byte3: I32.U8 do
    loop Validate do
      # We got to the end!
      if i === str_len do
        return(1)
      end

      # if i > str_len do
      #   return(0)
      # end

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

          i = i + 2
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

          i = i + 3
          Validate.continue()

        # 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
        I32.band(byte0, 0xF8) === 0xF0 ->
          if i + 3 >= str_len do
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
          # if (byte0 === 0xF0 &&& I32.lt_u(I32.band(byte1, 0xF0), 0x90)) or
          #      (byte0 === 0xF4 &&& I32.gt_u(I32.band(byte1, 0xF0), 0x8F)) do
          #   return(0)
          # end

          unless I32.band(byte1, 0xC0) === 0x80 &&&
                   I32.band(byte2, 0xC0) === 0x80 &&&
                   I32.band(byte3, 0xC0) === 0x80 do
            return(0)
          end

          i = i + 4
          Validate.continue()

        # Invalid UTF-8 byte
        true ->
          return(0)
      end

      Validate.continue()
    end

    1
  end

  @doc """
  Returns the number of Unicode graphemes in a UTF-8 string.
  
  Handles basic grapheme clusters and counts emoji as a single character.
  
  This is a simplified implementation - full grapheme cluster detection
  would require a more complex state machine and Unicode data tables.
  For the purpose of this implementation, we handle these cases:
  1. Standard UTF-8 code points
  2. Emoji sequences including ZWJ sequences
  """
  defw length(str: Str), I32, 
    i: I32, 
    count: I32, 
    byte0: I32.U8, 
    in_emoji_sequence: I32, 
    prev_was_emoji: I32 do
      
    if str[:size] === 0 do
      return(0)
    end

    i = 0
    count = 0
    in_emoji_sequence = 0
    prev_was_emoji = 0

    loop EachOctet do
      if i >= str[:size] do
        return(count)
      end

      byte0 = Memory.load!(I32.U8, str[:ptr] + i)

      # Check for emoji sequence or zero-width joiner (ZWJ)
      # ZWJ is E2 80 8D in UTF-8
      if i + 2 < str[:size] &&& 
         byte0 === 0xE2 &&&
         Memory.load!(I32.U8, str[:ptr] + i + 1) === 0x80 &&&
         Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x8D do
        # Found a ZWJ - continue emoji sequence
        in_emoji_sequence = 1
        i = i + 3
        EachOctet.continue()
      end

      # Check for variation selectors (VS15, VS16) used with emoji
      # VS15 is EF B8 8E, VS16 is EF B8 8F in UTF-8
      if i + 2 < str[:size] &&&
         byte0 === 0xEF &&&
         Memory.load!(I32.U8, str[:ptr] + i + 1) === 0xB8 &&&
         (Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x8E ||| 
          Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x8F) do
        # Found a variation selector - continue emoji sequence
        in_emoji_sequence = 1
        i = i + 3
        EachOctet.continue()
      end

      # Check for emoji modifier (skin tone)
      # These start with F0 9F 8F in UTF-8
      if i + 3 < str[:size] &&&
         byte0 === 0xF0 &&&
         Memory.load!(I32.U8, str[:ptr] + i + 1) === 0x9F &&&
         Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x8F do
        # Found a skin tone modifier - continue emoji sequence
        in_emoji_sequence = 1
        i = i + 4
        EachOctet.continue()
      end

      # Basic UTF-8 decoding
      cond result: nil do
        # 0xxxxxxx (ASCII)
        I32.band(byte0, 0x80) === 0x00 ->
          i = i + 1
          if in_emoji_sequence === 0 do
            count = count + 1
          end
          in_emoji_sequence = 0
          prev_was_emoji = 0

        # 110xxxxx 10xxxxxx (2-byte UTF-8)
        I32.band(byte0, 0xE0) === 0xC0 ->
          i = i + 2
          if in_emoji_sequence === 0 do
            count = count + 1
          end
          in_emoji_sequence = 0
          prev_was_emoji = 0

        # 1110xxxx 10xxxxxx 10xxxxxx (3-byte UTF-8)
        I32.band(byte0, 0xF0) === 0xE0 ->
          i = i + 3
          if in_emoji_sequence === 0 do
            count = count + 1
          end
          in_emoji_sequence = 0
          prev_was_emoji = 0

        # 11110xxx 10xxxxxx 10xxxxxx 10xxxxxx (4-byte UTF-8, including emoji)
        I32.band(byte0, 0xF8) === 0xF0 ->
          i = i + 4
          
          # Most emoji start with F0 9F in UTF-8
          if byte0 === 0xF0 &&& 
             i - 3 < str[:size] &&&
             Memory.load!(I32.U8, str[:ptr] + i - 3) === 0xF0 &&&
             Memory.load!(I32.U8, str[:ptr] + i - 2) === 0x9F do
            
            if prev_was_emoji === 0 &&& in_emoji_sequence === 0 do
              count = count + 1
            end
            
            prev_was_emoji = 1
            in_emoji_sequence = 1
          else
            if in_emoji_sequence === 0 do
              count = count + 1
            end
            in_emoji_sequence = 0
            prev_was_emoji = 0
          end
      end

      EachOctet.continue()
    end

    count
  end
end
