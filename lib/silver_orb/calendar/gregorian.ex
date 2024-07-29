defmodule SilverOrb.Calendar.Gregorian do
  use Orb

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
end
