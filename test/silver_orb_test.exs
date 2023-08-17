defmodule SilverOrbTest do
  use ExUnit.Case
  doctest SilverOrb

  test "greets the world" do
    assert SilverOrb.hello() == :world
  end
end
