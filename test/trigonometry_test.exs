defmodule TrigonometryTest do
  use ExUnit.Case, async: true

  setup do
    wat = Orb.to_wat(SilverOrb.Math.Trigonometry)
    binding()
  end

  setup %{wat: wat} do

    {:ok, pid} = Wasmex.start_link(%{bytes: wat})

    %{pid: pid}
  end

  test "cos", %{pid: pid} do
    {a, b} = cos_ab(pid, 1.0)
    assert_in_delta a, b, 0.01

    {a, b} = cos_ab(pid, 2.0)
    assert_in_delta a, b, 0.01

    # {a, b} = cos_ab(pid, 3.0)
    # assert_in_delta a, b, 0.01

    # {a, b} = cos_ab(pid, 4.0)
    # assert_in_delta a, b, 0.01
  end

  defp cos_ab(pid, x) do
    {:ok, [a]} = Wasmex.call_function(pid, :cos, [x])
    b = :math.cos(x)
    {a, b}
  end
end
