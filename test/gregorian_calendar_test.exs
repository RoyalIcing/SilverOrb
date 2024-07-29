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

  test "day_of_week", %{instance: instance} do
    assert 1 = Instance.call(instance, "day_of_week", 2016, 10, 31)
    assert 2 = Instance.call(instance, "day_of_week", 2016, 11, 1)
    assert 3 = Instance.call(instance, "day_of_week", 2016, 11, 2)
    assert 4 = Instance.call(instance, "day_of_week", 2016, 11, 3)
    assert 5 = Instance.call(instance, "day_of_week", 2016, 11, 4)
    assert 6 = Instance.call(instance, "day_of_week", 2016, 11, 5)
    assert 7 = Instance.call(instance, "day_of_week", 2016, 11, 6)

    start_date = ~D[1700-01-01]
    end_date = ~D[3000-01-10]

    Date.range(start_date, end_date)
    |> Enum.each(fn date ->
      expected_weekday = Date.day_of_week(date)

      assert expected_weekday =
               Instance.call(instance, "day_of_week", date.year, date.month, date.day)
    end)
  end
end
