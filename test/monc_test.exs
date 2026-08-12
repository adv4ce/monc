defmodule MoncTest do
  use ExUnit.Case
  doctest Monc

  test "greets the world" do
    assert Monc.hello() == :world
  end
end
