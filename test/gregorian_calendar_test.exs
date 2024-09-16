defmodule GregorianCalendarTest do
  use ExUnit.Case, async: true

  alias OrbWasmtime.Instance

  setup do
    wat = Orb.to_wat(SilverOrb.Calendar.Gregorian)
    wasm = Orb.to_wat(SilverOrb.Calendar.Gregorian)
    binding()
  end

  setup %{wasm: wasm} do
    instance = Instance.run(wasm)

    %{instance: instance}
  end

  # test "day_of_week", %{pid: pid} do
  #   assert {:ok, [1]} = Wasmex.call_function(pid, "day_of_week", [2016, 10, 31])
  #   assert {:ok, [2]} = Wasmex.call_function(pid, "day_of_week", [2016, 11, 1])
  #   assert {:ok, [3]} = Wasmex.call_function(pid, "day_of_week", [2016, 11, 2])
  #   assert {:ok, [4]} = Wasmex.call_function(pid, "day_of_week", [2016, 11, 3])
  #   assert {:ok, [5]} = Wasmex.call_function(pid, "day_of_week", [2016, 11, 4])
  #   assert {:ok, [6]} = Wasmex.call_function(pid, "day_of_week", [2016, 11, 5])
  #   assert {:ok, [7]} = Wasmex.call_function(pid, "day_of_week", [2016, 11, 6])

  #   start_date = ~D[1800-01-01]
  #   end_date = ~D[2200-01-10]

  #   # Create a range of dates
  #   date_range = Date.range(start_date, end_date)

  #   # Enum.each(date_range, fn date ->
  #   #   expected_weekday = Date.day_of_week(date)

  #   #   assert {:ok, [expected_weekday]} =
  #   #            Wasmex.call_function(pid, "day_of_week", [date.year, date.month, date.day])
  #   # end)

  #   Task.async_stream(
  #     date_range,
  #     fn date ->
  #       expected_weekday = Date.day_of_week(date)

  #       assert {:ok, [expected_weekday]} =
  #                Wasmex.call_function(pid, "day_of_week", [date.year, date.month, date.day])
  #     end,
  #     ordered: false
  #   )
  #   |> Stream.run()
  # end

  test "leap_year?", %{instance: instance} do
    assert 1 = Instance.call(instance, "leap_year?", 2000)
    assert 0 = Instance.call(instance, "leap_year?", 2001)
    assert 0 = Instance.call(instance, "leap_year?", 2015)
    assert 1 = Instance.call(instance, "leap_year?", 2016)
    assert 1 = Instance.call(instance, "leap_year?", 2020)
    assert 0 = Instance.call(instance, "leap_year?", 2100)

    1700..3000
    |> Enum.take_random(1234)
    |> Enum.each(fn year ->
      expected = if Calendar.ISO.leap_year?(year), do: 1, else: 0

      assert expected === Instance.call(instance, "leap_year?", year)
    end)
  end

  test "days_in_month", %{instance: instance} do
    assert 31 = Instance.call(instance, "days_in_month", 2000, 1)
    assert 29 = Instance.call(instance, "days_in_month", 2000, 2)
    assert 31 = Instance.call(instance, "days_in_month", 2000, 3)
    assert 30 = Instance.call(instance, "days_in_month", 2000, 4)
    assert 28 = Instance.call(instance, "days_in_month", 2100, 2)

    for(year <- 1700..3000, month <- 1..12, do: {year, month})
    |> Enum.each(fn {year, month} ->
      expected = Calendar.ISO.days_in_month(year, month)

      assert expected === Instance.call(instance, "days_in_month", year, month)
    end)
  end

  test "day_of_week", %{instance: instance} do
    assert 1 = Instance.call(instance, "day_of_week", 2016, 10, 31)
    assert 2 = Instance.call(instance, "day_of_week", 2016, 11, 1)
    assert 3 = Instance.call(instance, "day_of_week", 2016, 11, 2)
    assert 4 = Instance.call(instance, "day_of_week", 2016, 11, 3)
    assert 5 = Instance.call(instance, "day_of_week", 2016, 11, 4)
    assert 6 = Instance.call(instance, "day_of_week", 2016, 11, 5)
    assert 7 = Instance.call(instance, "day_of_week", 2016, 11, 6)

    Date.range(~D[1700-01-01], ~D[3000-01-10])
    |> Enum.take_random(1234)
    |> Enum.each(fn date ->
      expected_weekday = Date.day_of_week(date)
      wasm_weekday = Instance.call(instance, "day_of_week", date.year, date.month, date.day)

      assert expected_weekday === wasm_weekday
    end)
  end
end
