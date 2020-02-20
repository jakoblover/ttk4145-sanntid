defmodule FsmTest do
  use ExUnit.Case
  doctest Fsm

  test "greets the world" do
    assert Fsm.hello() == :world
  end
end
