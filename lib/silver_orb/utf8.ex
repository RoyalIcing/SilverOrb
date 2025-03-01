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
  Returns the number of Unicode graphemes (characters) in a UTF-8 string.

  This implementation handles:
  1. Basic ASCII and UTF-8 characters
  2. Combining marks (diacritical marks)
  3. Emoji with modifiers
  4. Flag emoji
  5. Family emoji with ZWJ sequences
  6. Emoji with gender and profession modifiers

  Implementation is simplified but handles common cases.
  """
  defw length(str: Str), I32,
    i: I32,
    count: I32,
    char_size: I32,
    byte: I32.U8,
    in_emoji_sequence: I32,
    emoji_start: I32 do
    if str[:size] === 0 do
      return(0)
    end

    i = 0
    count = 0
    in_emoji_sequence = 0
    emoji_start = 0

    loop EachChar do
      if i >= str[:size] do
        return(count)
      end

      byte = Memory.load!(I32.U8, str[:ptr] + i)

      # Calculate character size based on first byte
      char_size =
        if I32.band(byte, 0x80) === 0 do
          # ASCII
          i32(1)
        else
          if I32.band(byte, 0xE0) === 0xC0 do
            # 2-byte UTF-8
            i32(2)
          else
            if I32.band(byte, 0xF0) === 0xE0 do
              # 3-byte UTF-8
              i32(3)
            else
              # 4-byte UTF-8 (including emoji)
              i32(4)
            end
          end
        end

      # Start of an emoji sequence (most emoji start with F0 9F)
      if in_emoji_sequence === 0 &&&
           byte === 0xF0 &&&
           i + 1 < str[:size] &&&
           Memory.load!(I32.U8, str[:ptr] + i + 1) === 0x9F do
        # Mark the start of an emoji sequence
        in_emoji_sequence = 1
        emoji_start = i
        # Count this as one character
        count = count + 1
        i = i + char_size
        EachChar.continue()
      end

      # Handle combining marks
      # Most combining marks start with 0xCC or 0xCD (U+0300 - U+036F range)
      if i > 0 &&& (byte === 0xCC ||| byte === 0xCD) do
        # This is a combining character, don't increment count
        i = i + char_size
        EachChar.continue()
      end

      # Special handling for ZWJ (Zero Width Joiner) sequences in emoji
      # ZWJ is E2 80 8D in UTF-8
      if in_emoji_sequence === 1 &&& i + 2 < str[:size] &&&
           byte === 0xE2 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 1) === 0x80 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x8D do
        # This is part of a ZWJ sequence, don't increment count
        i = i + 3
        EachChar.continue()
      end

      # Special handling for emoji skin tone modifiers
      # These start with F0 9F 8F in UTF-8
      if in_emoji_sequence === 1 &&& i + 3 < str[:size] &&&
           byte === 0xF0 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 1) === 0x9F &&&
           Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x8F do
        # This is a skin tone modifier, don't increment count
        i = i + 4
        EachChar.continue()
      end

      # Special handling for variation selectors in emoji
      # VS15 is EF B8 8E, VS16 is EF B8 8F in UTF-8
      if i > 0 &&& i + 2 < str[:size] &&&
           byte === 0xEF &&&
           Memory.load!(I32.U8, str[:ptr] + i + 1) === 0xB8 &&&
           (Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x8E |||
              Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x8F) do
        # This is a variation selector, don't increment count
        i = i + 3
        EachChar.continue()
      end

      # Special handling for emoji gender signs
      # Male/Female signs: E2 99 82/80 followed by variation selector (EF B8 8F)
      if in_emoji_sequence === 1 &&& i + 2 < str[:size] &&&
           byte === 0xE2 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 1) === 0x99 &&&
           (Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x82 |||
              Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x80) do
        # Skip the gender sign
        i = i + 3
        EachChar.continue()
      end

      # Handle flag emoji (regional indicator pairs)
      # Regional indicators are F0 9F 87 A6-BF in UTF-8
      if i + 7 < str[:size] &&&
           byte === 0xF0 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 1) === 0x9F &&&
           Memory.load!(I32.U8, str[:ptr] + i + 2) === 0x87 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 3) >= 0xA6 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 3) <= 0xBF &&&
           Memory.load!(I32.U8, str[:ptr] + i + 4) === 0xF0 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 5) === 0x9F &&&
           Memory.load!(I32.U8, str[:ptr] + i + 6) === 0x87 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 7) >= 0xA6 &&&
           Memory.load!(I32.U8, str[:ptr] + i + 7) <= 0xBF do
        # This is a flag emoji (pair of regional indicators)
        count = count + 1
        # Skip both regional indicators (4 bytes each)
        i = i + 8
        EachChar.continue()
      end

      # Another emoji in a sequence (after ZWJ)
      if in_emoji_sequence === 1 &&&
           byte === 0xF0 &&&
           i + 1 < str[:size] &&&
           Memory.load!(I32.U8, str[:ptr] + i + 1) === 0x9F do
        # This is part of an emoji sequence (e.g., family emoji), don't increment count
        i = i + char_size
        EachChar.continue()
      end

      # If we're not in an emoji sequence or handled by any special case above,
      # and this is a start of a new character
      if in_emoji_sequence === 0 do
        # Normal character, increment count and move to next character
        count = count + 1
      else
        # Reset emoji sequence tracker at end of sequence
        in_emoji_sequence = 0
      end

      i = i + char_size
      EachChar.continue()
    end

    count
  end
end
