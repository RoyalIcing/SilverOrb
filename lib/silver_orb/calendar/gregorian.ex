defmodule SilverOrb.Calendar.Gregorian do
  use Orb

  defw leap_year?(year: I32), I32 do
    I32.rem_u(year, 4) === 0 &&& (I32.rem_u(year, 100) !== 0 or I32.rem_u(year, 400) === 0)
  end

  defw days_in_month(year: I32, month: I32), I32 do
    if month === 2, do: return(28 + leap_year?(year))

    [4, 6, 9, 11]
    |> Enum.map(fn m -> m === month end)
    |> Enum.reduce(&I32.or/2)
    |> if(do: i32(30), else: i32(31))
  end

  defw day_of_week(year: I32, month: I32, day: I32), I32, k: I32, j: I32, weekday: I32 do
    if month < 3 do
      month = month + 12
      year = year - 1
    end

    k = I32.rem_u(year, 100)
    j = I32.div_u(year, 100)

    weekday = I32.rem_u(day + 13 * (month + 1) / 5 + k + k / 4 + j / 4 + 5 * j, 7)

    # Adjust the result to make Sunday 0 instead of Saturday 0
    I32.rem_u(weekday + 5, 7) + 1
  end

  # defw add_days(year: I32, month: I32, day: I32, days_to_add: I32), {I32, I32, I32} do
  #   if days_to_add === 0 do
  #     {year, month, day}
  #   else
  #     {year, month, day}
  #   end
  # end
end
