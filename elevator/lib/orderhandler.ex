defmodule OrderHandler do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, name, name: __MODULE__)
  end

  def init(name) do
    IO.puts("I am booting")
    orders = elem(Enum.at(:dets.lookup(String.to_atom(name), :elev), 0), 1)
    {:ok, {orders, [], String.to_atom(name)}}
  end

  ###
  # Server call and cast handles
  ###

  @doc """
  Adds a new order to list of orders that should be handled
  Removes duplicate orders
  Turns on the respective order light
  Stores the order to disk
  """
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
    :dets.insert(name, {:elev, orders})
    Driver.set_order_button_light(order.order_type, order.floor, :on)
    data = {orders, requests, name}
    {:noreply, data}
  end

  @doc """
  Deletes an order from order list
  Turns the respective order button light off
  Tell watchdog the order has been handled
  """
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
    orders = elem(data, 0)
    :dets.insert(name, {:elev, orders})
    {:noreply, data}
  end

  @doc """
  Adds a request for an order to be handled
  Tells all the watchdogs on all nodes about the new order
  If the request is a cab order, the current node should handle it immediately
  """
  def handle_cast({:add_request, request}, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    name = elem(data, 2)
    requests = requests ++ [request]
    requests = Enum.uniq(requests)
    data = {orders, requests, name}

    nodes = Network.all_nodes()
    nodes |> Enum.map(fn node -> Watchdog.new_request(node, request) end)

    if request.order_type == :cab do
      OrderHandler.new_order(request)
    end

    {:noreply, data}
  end

  @doc """
  Delete a request for a given order
  """
  def handle_cast({:delete_request, request}, data) do
    orders = elem(data, 0)
    name = elem(data, 2)
    data = {orders, List.delete(elem(data, 1), request), name}
    {:noreply, data}
  end

  @doc """
  Fetches all current orders
  """
  def handle_call(:get, _from, data) do
    orders = elem(data, 0)
    {:reply, orders, data}
  end

  ###
  # Server API
  ###

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
