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
end
