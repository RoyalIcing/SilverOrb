defmodule SilverOrb.ISO8601 do
  use Orb

  Memory.pages(2)

  defp wrap_tuple(tuple) do
    %Orb.InstructionSequence{body: [tuple]}
  end

  defp empty_date() do
    wrap_tuple({0, 0, 0})
  end

  defp invalid_time() do
    wrap_tuple({-1, 0, 0, 0})
  end

  defp leap_year?(year) do
    Orb.snippet do
      I32.rem_u(year, 4) === 0 &&& (I32.rem_u(year, 100) !== 0 or I32.rem_u(year, 400) === 0)
    end
  end

  defp parse_digit(mut_var, str_ptr, fail_instruction) do
    Orb.snippet do
      Memory.load!(I32.U8, str_ptr)
      mut_var.write
      if mut_var.read < ?0 or mut_var.read > ?9, do: fail_instruction
      mut_var.read - ?0
      mut_var.write
    end
  end

  defw parse_date(str: Str), {I32, I32, I32}, year: I32, month: I32, day: I32, char: I32.U8 do
    # Control.block Valid, {I32, I32, I32} do
    Control.block Valid do
      if str[:size] !== 10, do: Valid.break()

      Control.block Year do
        parse_digit(mut!(char), str[:ptr], Valid.break())
        year = char * 1000

        parse_digit(mut!(char), str[:ptr] + 1, Valid.break())
        year = year + char * 100

        parse_digit(mut!(char), str[:ptr] + 2, Valid.break())
        year = year + char * 10

        parse_digit(mut!(char), str[:ptr] + 3, Valid.break())
        year = year + char

        if Memory.load!(I32.U8, str[:ptr] + 4) !== ?- do
          Valid.break()
        end
      end

      Control.block Month do
        parse_digit(mut!(char), str[:ptr] + 5, Valid.break())
        month = char * 10

        parse_digit(mut!(char), str[:ptr] + 6, Valid.break())
        month = month + char

        if Memory.load!(I32.U8, str[:ptr] + 7) !== ?- do
          Valid.break()
        end

        if month > 12, do: Valid.break()
      end

      Control.block Day do
        parse_digit(mut!(char), str[:ptr] + 8, Valid.break())
        day = char * 10

        parse_digit(mut!(char), str[:ptr] + 9, Valid.break())
        day = day + char

        if day > 31, do: Valid.break()

        # February in leap years has 29 days
        if month === 2 &&& day > 29, do: Valid.break()
        # February not in leap years has 28 days
        if month === 2 &&& not leap_year?(year) &&& day > 28, do: Valid.break()

        # Months with 30 days
        if (month === 5 or month === 6 or month === 9 or month === 11) &&& day > 30,
          do: Valid.break()
      end

      return(wrap_tuple({year, month, day}))
    end

    empty_date()
  end

  defw parse_time(str: Str), {I32, I32, I32, I32},
    ptr: I32.U8.UnsafePointer,
    hours: I32,
    minutes: I32,
    seconds: I32,
    microseconds: I32,
    char: I32.U8 do
    Control.block Valid do
      if str[:size] < 8, do: Valid.break()

      ptr = str[:ptr]

      if ptr[at!: 0] === ?T do
        ptr = ptr + 1
      end

      Control.block Hours do
        parse_digit(mut!(char), ptr, Valid.break())
        hours = char * 10

        parse_digit(mut!(char), ptr + 1, Valid.break())
        hours = hours + char

        if Memory.load!(I32.U8, ptr + 2) !== ?: do
          Valid.break()
        end

        if hours >= 24, do: Valid.break()
      end

      Control.block Minutes do
        parse_digit(mut!(char), ptr + 3, Valid.break())
        minutes = char * 10

        parse_digit(mut!(char), ptr + 4, Valid.break())
        minutes = minutes + char

        if Memory.load!(I32.U8, ptr + 5) !== ?: do
          Valid.break()
        end

        if minutes >= 60, do: Valid.break()
      end

      Control.block Seconds do
        parse_digit(mut!(char), ptr + 6, Valid.break())
        seconds = char * 10

        parse_digit(mut!(char), ptr + 7, Valid.break())
        seconds = seconds + char

        if seconds >= 60, do: Valid.break()
      end

      ptr = ptr + 8

      if ptr[at!: 0] === ?. do
        ptr = ptr + 1

        # loop 1..6 do
        # loop _ <- 1..6 do
        inline for _ <- 1..6 do
          wasm do
            if ptr - str[:ptr] < str[:size] do
              parse_digit(mut!(char), ptr, Valid.break())
              microseconds = microseconds * 10 + char
              ptr = ptr + 1
            else
              microseconds = microseconds * 10
            end
          end
        end
        |> Orb.InstructionSequence.new()
      end

      # If there are still characters left, it’s invalid.
      if ptr - str[:ptr] < str[:size] do
        Valid.break()
      end

      return(wrap_tuple({hours, minutes, seconds, microseconds}))
    end

    # |> if do
    #   return(wrap_tuple({hours, minutes, seconds, microseconds}))
    # else
    #   invalid_time()
    # end

    invalid_time()
  end

  @doc """
  Format a date as a string in the ISO8901 format `YYYY-MM-DD`.
  """
  defw format_date(year: I32, month: I32, day: I32, into_str: Str), Str, max_size: I32 do
    max_size = into_str[:size]
    into_str = {into_str[:ptr], 0}

    Control.block Valid do
      if year < 0 or year > 9999, do: Valid.break()
      if month < 1 or month > 12, do: Valid.break()
      if day < 1 or day > 31, do: Valid.break()

      Memory.store!(I32.U8, into_str[:ptr], I32.div_u(year, 1000) + ?0)
      Memory.store!(I32.U8, into_str[:ptr] + 1, I32.div_u(I32.rem_u(year, 1000), 100) + ?0)
      Memory.store!(I32.U8, into_str[:ptr] + 2, I32.div_u(I32.rem_u(year, 100), 10) + ?0)
      Memory.store!(I32.U8, into_str[:ptr] + 3, I32.rem_u(year, 10) + ?0)

      Memory.store!(I32.U8, into_str[:ptr] + 4, ?-)

      Memory.store!(I32.U8, into_str[:ptr] + 5, I32.div_u(month, 10) + ?0)
      Memory.store!(I32.U8, into_str[:ptr] + 6, I32.rem_u(month, 10) + ?0)

      Memory.store!(I32.U8, into_str[:ptr] + 7, ?-)

      Memory.store!(I32.U8, into_str[:ptr] + 8, I32.div_u(day, 10) + ?0)
      Memory.store!(I32.U8, into_str[:ptr] + 9, I32.rem_u(day, 10) + ?0)

      into_str = {into_str[:ptr], 10}

      # return(into_str)
    end

    # into_str[:size] = 0
    {into_str[:ptr], into_str[:size]}
    # into_str
  end

  defw format_time(hours: I32, minutes: I32, seconds: I32, microseconds: I32, into_str: Str), Str,
    max_size: I32 do
    max_size = into_str[:size]
    into_str = {into_str[:ptr], 0}

    Control.block Valid do
      if hours < 0 or hours >= 24, do: Valid.break()
      if minutes < 0 or minutes >= 60, do: Valid.break()
      if seconds < 0 or seconds >= 60, do: Valid.break()
      if microseconds < 0 or microseconds >= 1_000_000, do: Valid.break()

      Memory.store!(I32.U8, into_str[:ptr], I32.div_u(hours, 10) + ?0)
      Memory.store!(I32.U8, into_str[:ptr] + 1, I32.rem_u(hours, 10) + ?0)

      Memory.store!(I32.U8, into_str[:ptr] + 2, ?:)

      Memory.store!(I32.U8, into_str[:ptr] + 3, I32.div_u(minutes, 10) + ?0)
      Memory.store!(I32.U8, into_str[:ptr] + 4, I32.rem_u(minutes, 10) + ?0)

      Memory.store!(I32.U8, into_str[:ptr] + 5, ?:)

      Memory.store!(I32.U8, into_str[:ptr] + 6, I32.div_u(seconds, 10) + ?0)
      Memory.store!(I32.U8, into_str[:ptr] + 7, I32.rem_u(seconds, 10) + ?0)

      # if microseconds > 0 do
      #   Memory.store!(I32.U8, into_str[:ptr] + 8, ?.)

      # inline for i <- 1..6 do
      #   Memory.store!(I32.U8, into_str[:ptr] + 8 + i, I32.div_u(microseconds, 10 ** (6 - i)) + ?0)
      #   microseconds = I32.rem_u(microseconds, 10 ** (6 - i))
      # end
      # end

      into_str = {into_str[:ptr], if(microseconds > 0, [result: I32], do: 8 + 7, else: 8)}
    end

    {into_str[:ptr], into_str[:size]}
  end
end
