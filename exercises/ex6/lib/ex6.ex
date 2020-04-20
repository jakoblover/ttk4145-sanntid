defmodule Ex6 do
  def main(args) do
    i = hd(args)
    Counter.start_link(0)
    Task_killer.start_link({0, 0})

    cond do
      i == "primary" ->
        IO.puts("I am primary")
        System.cmd("gnome-terminal", ["--", "./ex6", "secondary"])
        boot_node(i, 6800)
        Process.register(self(), :primary)
        sender()

      i == "secondary" ->
        IO.puts("I am backup")
        boot_node(i, 6801)
        Process.register(self(), :secondary)
        waiter()
    end
  end

  def waiter() do
    receive do
      msg ->
        Counter.set(msg)
    after
      2000 ->
        Node.stop()
        Process.unregister(:secondary)
        Process.register(self(), :primary)
        :gen_udp.close(Task_killer.socket())
        Process.exit(Task_killer.pid(), :kill)
        boot_node("primary", 6800)
        System.cmd("gnome-terminal", ["--", "./ex6", "secondary"])
        sender()
    end

    waiter()
  end

  def sender() do
    Process.sleep(200)
    Counter.increment()
    IO.puts(Counter.value())
    sender()
  end

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

  def ip_to_string(ip) do
    :inet.ntoa(ip) |> to_string()
  end

  def boot_node(node_name, port, tick_time \\ 15000) do
    ip = get_my_ip() |> ip_to_string()
    full_name = node_name <> "@" <> ip
    Node.start(String.to_atom(full_name), :longnames, tick_time)
    Node.set_cookie(Node.self(), :kjeks)
    {:ok, pid} = Heartbeat.start_link({ip, port, node_name, 0})
    Task_killer.set({Task_killer.socket(), pid})
  end
end

defmodule Heartbeat do
  use Task

  def start_link(data) do
    port = elem(data, 1)
    init = elem(data, 3)
    {:ok, socket} = :gen_udp.open(port, active: false, broadcast: true)
    Task_killer.set({socket, Task_killer.pid()})
    Task.start(__MODULE__, :run, [socket, data])
  end

  def run(socket, data) do
    port = elem(data, 1)

    if port == 6800 do
      receive_port = 6801
      :gen_udp.send(socket, {255, 255, 255, 255}, receive_port, elem(data, 2))
    else
      receive_port = 6800
      :gen_udp.send(socket, {255, 255, 255, 255}, receive_port, elem(data, 2))
    end

    {from, ip} =
      case :gen_udp.recv(socket, 100, 1000) do
        {:ok, {ip, _port, data}} -> {data, Ex6.ip_to_string(ip)}
        {:error, _} -> {:error, :could_not_get_ip}
      end

    if is_binary(ip) do
      (to_string(from) <> "@" <> ip) |> String.to_atom() |> Node.ping()
      to = (to_string(from) <> "@" <> ip) |> String.to_atom()
      from = to_string(from) |> String.to_atom()
      number = Counter.value()
      send({from, to}, number)
    else
      IO.puts("No nodes detected")
    end

    Process.sleep(200)
    run(socket, data)
  end
end
