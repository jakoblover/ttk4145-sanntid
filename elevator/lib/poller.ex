defmodule Poller do
  require Driver
  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def init(state), do: {:ok, state}
end
