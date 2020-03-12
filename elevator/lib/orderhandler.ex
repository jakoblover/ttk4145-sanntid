defmodule OrderHandler do
  use GenServer

  def start_link([]) do
    GenServer.start_link(__MODULE__, {[], []}, name: __MODULE__)
  end

  def init({[], []}) do
    {:ok, {[], []}}
  end

  def handle_cast({:new_order, order}, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    orders = orders ++ [order]
    IO.inspect(orders, label: "The current orders are")
    data = {orders, requests}
    {:noreply, data}
  end

  def handle_cast(:delete_order, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    orders = tl(orders)
    IO.inspect(orders, label: "The new orders are")
    data = {orders, requests}
    # Tell watchdog to clear order
    {:noreply, data}
  end

  def handle_cast({:add_request, request}, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    requests = requests ++ [request]
    IO.inspect(requests, label: "The current requests are")
    data = {orders, requests}
    # Tell watchdog to add request
    # Send request to bid handler
    {:noreply, data}
  end

  def handle_cast(:delete_request, data) do
    orders = elem(data, 0)
    requests = elem(data, 1)
    requests = tl(requests)
    IO.inspect(requests, label: "The new requests are")
    data = {orders, requests}
    # Tell watchdog to clear request
    {:noreply, data}
  end

  def handle_call(:get, _from, data) do
    orders = elem(data, 0)
    IO.puts("Here are the orders")
    IO.inspect(orders, label: "The current orders are")
    IO.inspect(data, label: "The current data is")
    {:reply, orders, data}
  end

  def order_handeled() do
    GenServer.cast(__MODULE__, :delete_order)
  end

  def new_order(order) do
    GenServer.cast(__MODULE__, {:new_order, order})
  end

  def get_orders() do
    GenServer.call(__MODULE__, :get)
  end

  def add_request(request) do
    GenServer.cast(__MODULE__, {:add_request, request})
  end

  def bid_handeled() do
    GenServer.cast(__MODULE__, :delete_request)
  end
end
