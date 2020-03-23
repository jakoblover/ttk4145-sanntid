defmodule Task_killer do
  use Agent

  def start_link(initial_value) do
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def socket do
    Agent.get(__MODULE__, &elem(&1, 0))
  end

  def pid do
    Agent.get(__MODULE__, &elem(&1, 1))
  end

  def set(pid) do
    Agent.update(__MODULE__, &(&1 = pid))
  end
end
