defmodule Watchdog do
  use GenServer

  def start_link({port, name}) do
    GenServer.start_link(__MODULE__, {port, name}, name: __MODULE__)
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  def init({port, name}) do
    boot_node(name, port)
    {:ok, []}
  end

  def handle_info({:redistribute, request}, data) do
    IO.puts("Redistributing order")
    result = Enum.find(data, fn element -> match?({order, _}, element) end)
    data = List.delete(data, result)
    # IO.inspect(data)
    # Ask Bid handler to redistribute
    {:noreply, data}
  end

  def handle_cast({:new_request, request}, data) do
    timer_ref = Process.send_after(self(), {:redistribute, request}, 10000)
    # IO.inspect(timer_ref)
    data = data ++ [{request, timer_ref}]
    # IO.inspect(data)
    {:noreply, data}
  end

  def handle_cast({:order_handled, order}, data) do
    result = Enum.find(data, fn element -> match?({order, _}, element) end)
    # IO.inspect(data)
    data = List.delete(data, result)
    # IO.inspect(result)
    timer_ref = elem(result, 1)
    time_left = Process.cancel_timer(timer_ref)
    # IO.inspect(time_left)
    # IO.inspect(data)
    {:noreply, data}
  end

  def new_request(request) do
    GenServer.cast(__MODULE__, {:new_request, request})
  end

  def order_handled(order) do
    GenServer.cast(__MODULE__, {:order_handled, order})
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
    Heartbeat.start_link({ip, port, node_name})
  end
end

defmodule Heartbeat do
  use Task, restart: :permanent

  def start_link(data) do
    Task.start_link(__MODULE__, :run, [data])
  end

  def run(data) do
    port = elem(data, 1)
    {:ok, socket} = :gen_udp.open(port, active: false, broadcast: true)

    if port == 6800 do
      receive_port = 6801
      :gen_udp.send(socket, {255, 255, 255, 255}, receive_port, elem(data, 2))
    else
      receive_port = 6800
      :gen_udp.send(socket, {255, 255, 255, 255}, receive_port, elem(data, 2))
    end

    {from, ip} =
      case :gen_udp.recv(socket, 100, 1000) do
        {:ok, {ip, _port, data}} -> {data, Watchdog.ip_to_string(ip)}
        {:error, _} -> {:error, :could_not_get_ip}
      end

    if is_binary(ip) do
      (to_string(from) <> "@" <> ip) |> String.to_atom() |> Node.ping()
    else
      IO.puts("No nodes detected")
    end

    Process.sleep(200)
    :gen_udp.close(socket)
    run(data)
  end
end
