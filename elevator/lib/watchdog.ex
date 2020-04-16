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
    :dets.open_file(:disk_storage, type: :set)

    :dets.insert(
      :disk_storage,
      # {:elev,
      {String.to_atom(name),
       [
         #  {2, :hall_down},
         #  {2, :hall_up},
         #  {1, :cab},
         #  {3, :cab},
         #  {2, :hall_down},
         #  {0, :cab}
         # Order.new(2, :hall_down),
         # Order.new(2, :hall_up)
         # Order.new(1, :cab)
         # Order.new(3, :cab),
         # Order.new(2, :hall_down),
         # Order.new(0, :cab)
       ]}
    )

    boot_node(name, port)
    {:ok, []}
  end

  def handle_info({:redistribute, request}, data) do
    # IO.puts("Redistributing order")
    result = Enum.find(data, &(elem(&1, 0) == request))
    # IO.inspect(request)
    data = List.delete(data, result)

    # IO.inspect(request, label: "Redistributed order")
    # IO.inspect(data)

    # if elem(request, 1) == :cab and Counter.get() == 0 do
    if request.order_type == :cab and Counter.get() == 0 do
      # IO.puts("Cab order")
      Counter.set(1)
      # IO.inspect(data)
      Driver.set_motor_direction(:stop)
      OrderHandler.kill_orderhandler()
      ElevatorFSM.kill_fsm()
    end

    # if elem(request, 1) == :hall_down or elem(request, 1) == :hall_up do
    if request.order_type == :hall_down or request.order_type == :hall_up do
      # IO.puts("Bid handler job")
      # new_request(request)
      # Ask Bid handler to redistribute
    end

    {:noreply, data}
  end

  def handle_cast({:new_request, request}, data) do
    # IO.inspect(request, label: "New request")
    timer_ref = Process.send_after(self(), {:redistribute, request}, 100_000)
    # IO.inspect(timer_ref)
    data = data ++ [{request, timer_ref}]
    # IO.inspect(data, label: "data")
    {:noreply, data}
  end

  def handle_cast({:order_handled, order}, data) do
    # IO.puts("Handling order")

    if length(data) > 0 do
      result = Enum.find(data, &(elem(&1, 0) == order))
      data = List.delete(data, result)
      # IO.inspect(result)
      timer_ref = elem(result, 1)
      _time_left = Process.cancel_timer(timer_ref)
      # IO.inspect(order, label: "Watchdog: Removed order")
      # IO.inspect(time_left)
      # IO.inspect(data)
      {:noreply, data}
    else
      # IO.puts("Order not watched")
      {:noreply, data}
    end
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
    {:ok, pid} = Node.start(String.to_atom(full_name), :longnames)
    IO.inspect(Node.self())
    IO.inspect(pid)
    Node.set_cookie(Node.self(), :kjeks)
    # IO.inspect(Process.info(pid))
    Process.unregister(:net_sup)
    # IO.inspect(Process.info(pid))
    Process.register(pid, String.to_atom(node_name))
    # IO.inspect(Process.info(pid))
    # Process.register(self(), String.to_atom(node_name))
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
    {:ok, socket} = :gen_udp.open(port, active: false, broadcast: true, reuseaddr: true)

    :gen_udp.send(socket, {255, 255, 255, 255}, port, elem(data, 2))

    {from, ip} =
      case :gen_udp.recv(socket, 100, 1000) do
        {:ok, {ip, _port, data}} -> {data, Watchdog.ip_to_string(ip)}
        {:error, _} -> {:error, :could_not_get_ip}
      end

    if is_binary(ip) do
      nodename = (to_string(from) <> "@" <> ip) |> String.to_atom()
      Node.ping(nodename)

      if length(Node.list()) == 0 do
        send({String.to_atom(to_string(from)), nodename}, node())
      end
    else
      IO.puts("No nodes detected")
    end

    Process.sleep(200)
    :gen_udp.close(socket)
    run(data)
  end
end
