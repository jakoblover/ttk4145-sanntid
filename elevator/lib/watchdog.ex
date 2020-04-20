defmodule Watchdog do
  use GenServer

  def start_link({port, name}) do
    GenServer.start_link(__MODULE__, {port, name}, name: __MODULE__)
  end

  def stop do
    GenServer.stop(__MODULE__)
  end

  @spec init({any, binary}) :: {:ok, []}
  def init({port, name}) do
    :dets.open_file(String.to_atom(name), type: :set)
    :dets.open_file(:heis2, type: :set)

    # :dets.insert(String.to_atom(name), {:elev, []}) For testing

    boot_node(name, port)
    {:ok, []}
  end

  def handle_info({:redistribute, {request, node}}, data) do
    result = Enum.find(data, &(elem(&1, 0) == request))
    data = List.delete(data, result)

    if request.order_type == :cab and node == Node.self() and Agents.Counter.get() == 0 do
      IO.inspect("Restarting elevator because of cab order not cleared")
      Agents.Counter.set(1)
      Driver.set_motor_direction(:stop)
      ElevatorFSM.kill_fsm()
    end

    if request.order_type == :hall_down or request.order_type == :hall_up do
      BidHandler.distribute(request)
      OrderHandler.add_request(request)
    end

    {:noreply, data}
  end

  def handle_cast({:new_request, {request, node}}, data) do
    timer_ref = Process.send_after(self(), {:redistribute, {request, node}}, 20000)
    data = data ++ [{request, timer_ref}]
    {:noreply, data}
  end

  def handle_cast({:order_handled, order}, data) do
    if length(data) > 0 do
      remove_requests(data, order)
      {:noreply, data}
    else
      {:noreply, data}
    end
  end

  def remove_requests(data, order) do
    if Enum.find(data, &(elem(&1, 0) == order)) != nil do
      result = Enum.find(data, &(elem(&1, 0) == order))
      data = List.delete(data, result)

      try do
        timer_ref = elem(result, 1)
        _time_left = Process.cancel_timer(timer_ref)
      rescue
        e in ArgumentError -> IO.inspect(e, label: "Error")
      end

      remove_requests(data, order)
    end

    data
  end

  def new_request(request) do
    GenServer.cast(__MODULE__, {:new_request, request})
  end

  def new_request(node, request) do
    GenServer.cast({__MODULE__, node}, {:new_request, {request, node}})
  end

  def order_handled(order) do
    GenServer.cast(__MODULE__, {:order_handled, order})
  end

  def order_handled(node, order) do
    GenServer.cast({__MODULE__, node}, {:order_handled, order})
  end

  def boot_node(node_name, port, tick_time \\ 15000) do
    if Node.alive?() do
      "Node is already alive"
    else
      ip = Network.get_my_ip() |> Network.ip_to_string()
      IO.inspect(ip, label: "ip")
      full_name = node_name <> "@" <> ip
      {:ok, pid} = Node.start(String.to_atom(full_name), :longnames, tick_time)
      Node.set_cookie(Node.self(), :kjeks)
      Process.unregister(:net_sup)
      Process.register(pid, String.to_atom(node_name))
      Heartbeat.start_link({ip, port, node_name})
    end
  end
end

defmodule Heartbeat do
  use Task, restart: :permanent

  def start_link(data) do
    Task.start_link(__MODULE__, :run, [data])
  end

  def run(data) do
    port = elem(data, 1)
    {:ok, socket} = :gen_udp.open(port, active: false, broadcast: true, reuseaddr: true)

    :gen_udp.send(socket, {255, 255, 255, 255}, port, elem(data, 2))

    {from, ip} =
      case :gen_udp.recv(socket, 100, 1000) do
        {:ok, {ip, _port, data}} ->
          {data, Network.ip_to_string(ip)}

        {:error, _} ->
          {:error, :could_not_get_ip}
      end

    if is_binary(ip) do
      nodename = (to_string(from) <> "@" <> ip) |> String.to_atom()
      Node.ping(nodename)

      if length(Node.list()) == 0 do
        send({:heis1, :"heis1@10.0.0.16"}, node())
        send({:heis2, :"heis2@10.0.0.16"}, node())
      end
    else
      IO.puts("No nodes detected")

      if length(Node.list()) > 0 do
        Node.disconnect(hd(Node.list()))
      end
    end

    Process.sleep(200)
    :gen_udp.close(socket)
    run(data)
  end
end
