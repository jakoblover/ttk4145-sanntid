defmodule UdpkomTest do
  use ExUnit.Case
  doctest Udpkom

  test "greets the world" do
    assert Udpkom.hello() == :world
  end
end
