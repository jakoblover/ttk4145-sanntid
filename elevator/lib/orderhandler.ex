defmodule OrderHandler do
  use GenServer

  def start_link(name) do
    Process.sleep(500)
    GenServer.start_link(__MODULE__, name, name: __MODULE__)
  end

  def init(name) do
    send({:heis1, :"heis1@10.0.0.16"}, node())
    send({:heis2, :"heis2@10.0.0.16"}, node())
    orders = elem(Enum.at(:dets.lookup(String.to_atom(name), :elev), 0), 1)

    # IO.inspect(orders, label: "orders")

    if(length(orders) > 0) do
      for x <- 0..(length(orders) - 1) do
        Watchdog.new_request(elem(Enum.fetch(orders, x), 1))
      end
    end

    {:ok, {orders, [], String.to_atom(name)}}
  end

  def handle_cast({:new_order, order}, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    name = elem(data, 2)
    orders = orders ++ [order]
    orders = Enum.uniq(orders)

    IO.inspect(to_string(order.floor) <> " , " <> to_string(order.order_type),
      label: "I got the order"
    )

    request_handled(order)
    Driver.set_order_button_light(order.order_type, order.floor, :on)
    data = {orders, requests, name}
    {:noreply, data}
  end

  def handle_cast({:delete_order, order}, data) do
    requests = elem(data, 1)
    name = elem(data, 2)
    data = {List.delete(elem(data, 0), order), requests, name}

    if order.order_type == :cab do
      Driver.set_order_button_light(order.order_type, order.floor, :off)
    else
      nodes = Network.all_nodes()

      nodes
      |> Enum.map(fn node ->
        Driver.set_order_button_light(node, order.order_type, order.floor, :off)
      end)
    end

    Watchdog.order_handled(order)
    orders = elem(data, 0)
    :dets.insert(name, {:elev, orders})
    {:noreply, data}
  end

  def handle_cast({:add_request, request}, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    name = elem(data, 2)
    requests = requests ++ [request]
    data = {orders, requests, name}
    Watchdog.new_request(request)

    if request.order_type == :cab do
      OrderHandler.new_order(request)
    else
      # IO.inspect(request, label: "Request being sent to Bidhandler")
      BidHandler.distribute(request, length(orders))
    end

    {:noreply, data}
  end

  def handle_cast({:delete_request, request}, data) do
    orders = elem(data, 0)
    name = elem(data, 2)
    data = {orders, List.delete(elem(data, 1), request), name}
    {:noreply, data}
  end

  def handle_call(:get, _from, data) do
    # IO.inspect(data, label: "Data")
    orders = elem(data, 0)
    # IO.inspect(orders, label: "Getting orders")
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

  # def get_orders(node) do
  #   GenServer.call({__MODULE__, node}, :get)
  # end

  def add_request(request) do
    GenServer.cast(__MODULE__, {:add_request, request})
  end

  def request_handled(request) do
    GenServer.cast(__MODULE__, {:delete_request, request})
  end
end
