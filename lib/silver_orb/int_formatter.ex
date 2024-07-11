defmodule SilverOrb.IntFormatter do
  use Orb
  # use SilverOrb.BumpAllocator

  defmacro __using__(_) do
    quote do
      import Orb

      Orb.include(unquote(__MODULE__))
    end
  end

  Memory.pages(2)

  defw format_u32_char_count(value: I32),
       I32,
       digit_count: I32,
       digit: I32 do
    loop Digits do
      digit_count = I32.add(digit_count, 1)

      digit = I32.rem_u(value, 10)
      value = I32.div_u(value, 10)

      Digits.continue(if: I32.gt_u(value, 0))
    end

    digit_count
  end

  defw format_u32(value: I32, str_ptr: I32.U8.UnsafePointer),
       I32.U8.UnsafePointer,
       working_offset: I32.U8.UnsafePointer,
       last_offset: I32,
       digit: I32 do
    last_offset = I32.add(str_ptr, format_u32_char_count(value))
    # We then start from the back, as we have to print the digits in reverse.
    working_offset = last_offset

    loop Digits do
      working_offset = I32.sub(working_offset, 1)

      digit = I32.rem_u(value, 10)
      value = I32.div_u(value, 10)
      Memory.store!(I32.U8, working_offset, I32.add(?0, digit))

      Digits.continue(if: I32.gt_u(value, 0))
    end

    last_offset
  end
end
