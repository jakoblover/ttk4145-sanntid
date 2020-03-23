defmodule Ex6Test do
  use ExUnit.Case
  doctest Ex6

  test "greets the world" do
    assert Ex6.hello() == :world
  end
end
