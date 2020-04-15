defmodule OrderHandler do
  use GenServer

  # def start_link([]) do
  def start_link(name) do
    Process.sleep(500)
    # GenServer.start_link(__MODULE__, {[], []}, name: __MODULE__)
    GenServer.start_link(__MODULE__, name, name: __MODULE__)
    # IO.inspect(is_atom(__MODULE__))
    # IO.inspect(__MODULE__, label: "OrderHandler name")
  end

  # def init({[], []}) do
  def init(name) do
    # orders = elem(Enum.at(:dets.lookup(:disk_storage, :elev), 0), 1)
    orders = elem(Enum.at(:dets.lookup(:disk_storage, String.to_atom(name)), 0), 1)

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
    # IO.inspect(orders, label: "The current orders are")
    data = {orders, requests, name}
    Watchdog.new_request(order)
    {:noreply, data}
  end

  def handle_cast({:delete_order, order}, data) do
    requests = elem(data, 1)
    name = elem(data, 2)
    # IO.inspect(order)
    # IO.inspect(data)
    data = {List.delete(elem(data, 0), order), requests, name}
    # IO.inspect(data)
    Watchdog.order_handled(order)
    orders = elem(data, 0)
    :dets.insert(:disk_storage, {name, orders})
    {:noreply, data}
  end

  def handle_cast({:add_request, request}, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    name = elem(data, 2)
    requests = requests ++ [request]
    IO.inspect(requests, label: "The current requests are")
    data = {orders, requests, name}
    # Watchdog.new_request(request)
    # Send request to bid handler
    {:noreply, data}
  end

  def handle_cast(:delete_request, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    name = elem(data, 2)
    requests = tl(requests)
    # IO.inspect(requests, label: "The new requests are")
    data = {orders, requests, name}
    {:noreply, data}
  end

  def handle_call(:get, _from, data) do
    orders = elem(data, 0)
    # IO.puts("Here are the orders")
    # IO.inspect(orders, label: "The current orders are")
    # IO.inspect(data, label: "The current data is")
    {:reply, orders, data}
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

  def get_bid_from_node(node, order = %Order{}) do
    GenServer.cast({__MODULE__, node}, {:new_order, order})
  end

  def get_orders() do
    GenServer.call(__MODULE__, :get)
  end

  def add_request(request) do
    GenServer.cast(__MODULE__, {:add_request, request})
  end

  def bid_handled() do
    GenServer.cast(__MODULE__, :delete_request)
  end
end
