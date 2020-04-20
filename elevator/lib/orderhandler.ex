defmodule OrderHandler do
  use GenServer

  def start_link(name) do
    # Process.sleep(500)
    GenServer.start_link(__MODULE__, name, name: __MODULE__)
  end

  def init(name) do
    IO.puts("I am booting")
    # send({:heis1, :"heis1@10.0.0.16"}, node())
    # send({:heis2, :"heis2@10.0.0.16"}, node())
    orders = elem(Enum.at(:dets.lookup(String.to_atom(name), :elev), 0), 1)

    # IO.inspect(:dets.lookup(String.to_atom(name), :elev), label: "Dets")
    # orders2 = elem(Enum.at(:dets.lookup(:heis2, :elev), 0), 1)
    # IO.inspect(orders, label: "orders on startup")
    # IO.inspect(orders2, label: "orders on startup elev 2")

    # if(length(orders) > 0) do
    #   nodes = Network.all_nodes()

    #   # nodes
    #   # |> Enum.map(fn node ->
    #   #   Orders |> Enum.map(fn order -> Watchdog.new_request(node, order) end)
    #   # end)

    #   for node <- nodes, order <- orders do
    #     if order.order_type == :cab do
    #       IO.inspect(node, label: "Node")
    #       IO.inspect(order, label: "Order")
    #       Watchdog.order_handled(order)
    #       Watchdog.new_request(order)
    #     else
    #       IO.inspect(node, label: "Node")
    #       IO.inspect(order, label: "Order")
    #       Watchdog.order_handled(node, order)
    #       Watchdog.new_request(node, order)
    #     end
    #   end

    #   # orders |> Enum.map(fn order -> )
    #   # nodes |> Enum.map(fn node -> Watchdog.new_request(node, order) end)
    #   # nodes |> Enum.map(fn node -> )
    #   # for x <- 0..(length(orders) - 1) do
    #   #   nodes |> Enum.map(fn node -> Watchdog.new_request(node, order) end)
    #   #   Watchdog.order_handled(node, order)
    #   #   Watchdog.new_request(elem(Enum.fetch(orders, x), 1))
    #   # end
    # end

    {:ok, {orders, [], String.to_atom(name)}}
  end

  def handle_cast({:new_order, order}, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    name = elem(data, 2)
    # IO.inspect(name, label: "Name")
    orders = orders ++ [order]
    orders = Enum.uniq(orders)

    # IO.inspect(orders, label: "Orders in new orders")

    IO.inspect(to_string(order.floor) <> " , " <> to_string(order.order_type),
      label: "I got the order"
    )

    request_handled(order)
    :dets.insert(name, {:elev, orders})
    Driver.set_order_button_light(order.order_type, order.floor, :on)
    data = {orders, requests, name}
    {:noreply, data}
  end

  def handle_cast({:delete_order, order}, data) do
    requests = elem(data, 1)
    name = elem(data, 2)
    data = {List.delete(elem(data, 0), order), requests, name}
    nodes = Network.all_nodes()

    if order.order_type == :cab do
      Driver.set_order_button_light(order.order_type, order.floor, :off)
    else
      nodes
      |> Enum.map(fn node ->
        Driver.set_order_button_light(node, order.order_type, order.floor, :off)
      end)
    end

    nodes |> Enum.map(fn node -> Watchdog.order_handled(node, order) end)
    # Watchdog.order_handled(order)
    orders = elem(data, 0)
    :dets.insert(name, {:elev, orders})
    {:noreply, data}
  end

  def handle_cast({:add_request, request}, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    name = elem(data, 2)
    requests = requests ++ [request]
    requests = Enum.uniq(requests)
    data = {orders, requests, name}

    # if Enum.member?(requests, request) && length(requests) > 1 do
    #   IO.inspect(request, label: "Repeat request")
    # else
    nodes = Network.all_nodes()
    nodes |> Enum.map(fn node -> Watchdog.new_request(node, request) end)

    # Watchdog.new_request(request)

    if request.order_type == :cab do
      OrderHandler.new_order(request)
    end

    # end

    {:noreply, data}
  end

  def handle_cast({:delete_request, request}, data) do
    orders = elem(data, 0)
    name = elem(data, 2)
    data = {orders, List.delete(elem(data, 1), request), name}
    {:noreply, data}
  end

  def handle_call(:get, _from, data) do
    orders = elem(data, 0)
    {:reply, orders, data}
  end

  def can_handle_order(cab_state) do
    cab_state.direction == :stop and length(get_orders()) == 0
  end

  def kill_orderhandler do
    GenStateMachine.stop(__MODULE__, :normal, :infinity)
  end

  def order_handled(order) do
    GenServer.cast(__MODULE__, {:delete_order, order})
  end

  def new_order(order) do
    GenServer.cast(__MODULE__, {:new_order, order})
  end

  def new_order(node, order = %Order{}) do
    GenServer.cast({__MODULE__, node}, {:new_order, order})
  end

  def get_orders() do
    GenServer.call(__MODULE__, :get)
  end

  def add_request(request) do
    GenServer.cast(__MODULE__, {:add_request, request})
  end

  def request_handled(request) do
    GenServer.cast(__MODULE__, {:delete_request, request})
  end
end
