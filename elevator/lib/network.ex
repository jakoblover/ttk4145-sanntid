defmodule Network do
  def all_nodes do
    case [Node.self() | Node.list()] do
      [:nonode@nohost] -> {:error, :node_not_running}
      nodes -> nodes
    end
  end

  def get_my_ip do
    {:ok, socket} = :gen_udp.open(6789, active: false, broadcast: true)
    :ok = :gen_udp.send(socket, {255, 255, 255, 255}, 6789, "test packet")

    ip =
      case :gen_udp.recv(socket, 100, 1000) do
        {:ok, {ip, _port, _data}} -> ip
        {:error, _} -> {:error, :could_not_get_ip}
      end

    IO.inspect(ip, label: "ip in network")

    if ip == {:error, :could_not_get_ip} do
      IO.inspect("Error")
      :gen_udp.close(socket)
      get_my_ip()
    else
      IO.inspect("Returning ip")
      :gen_udp.close(socket)
      ip
    end
  end

  def ip_to_string(ip) do
    :inet.ntoa(ip) |> to_string()
  end
end
