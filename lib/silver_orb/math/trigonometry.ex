defmodule SilverOrb.Math.Trigonometry do
  use Orb

  # TODO: use more accurate CORDIC (Coordinate Rotation Digital Computer) algorithm instead
  # TODO: or adopt what Zig does, which is influenced by musl

  defw cos(x: F64), F64, x2: F64 do
    # Normalize x to [-pi, pi]
    x =
      x
      |> F64.div(3.14159265358979323846)
      |> F64.floor()
      |> F64.mul(3.14159265358979323846)
      |> F64.sub(x)

    # x^2
    x2 = F64.mul(x, x)

    # Polynomial approximation
    1.0 + x2 * -0.5 + x2 * x2 * 0.041666666666666664 + x2 * x2 * x2 * -0.001388888888888889

    # f64.const 1
    # local.get $x2
    # f64.const -0.5
    # f64.mul
    # f64.add
    # local.get $x2
    # local.get $x2
    # f64.mul
    # f64.const 0.041666666666666664
    # f64.mul
    # f64.add
    # local.get $x2
    # local.get $x2
    # f64.mul
    # local.get $x2
    # f64.mul
    # f64.const -0.001388888888888889
    # f64.mul
    # f64.add
  end

  # Sine approximation
  defw sin(x: F64), F64 do
    # sin(x) = cos(x - pi/2)
    x
    |> F64.sub(1.57079632679489661923)
    |> cos()
  end
end
