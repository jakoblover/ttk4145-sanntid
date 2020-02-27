defmodule Watchdog do
  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, name: __MODULE__)
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def init(state), do: {:ok, state}

  def get_my_ip do
    {:ok, socket} = :gen_udp.open(6789, active: false, broadcast: true)
    :ok = :gen_udp.send(socket, {255, 255, 255, 255}, 6789, "test packet")

    ip =
      case :gen_udp.recv(socket, 100, 1000) do
        {:ok, {ip, _port, _data}} -> ip
        {:error, _} -> {:error, :could_not_get_ip}
      end

    :gen_udp.close(socket)
    ip
  end
end
