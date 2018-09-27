defmodule KongakTest do
  use ExUnit.Case
  doctest Kongak

  test "greets the world" do
    assert Kongak.hello() == :world
  end
end
