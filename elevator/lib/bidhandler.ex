defmodule BidHandler do
  use GenServer
  @timeout 500

  # Initialization and startup functions

  def start_link([]) do
    GenServer.start_link(__MODULE__, {[], []}, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, []}
  end

  # User API
  def get_bids_on_order(order) do
    nodes = Network.all_nodes()

    all_bids = nodes |> Enum.map(fn node -> get_bid_from_node(node, order) end)

    all_bids |> Enum.reject(fn bid -> match?({:error, _}, bid) end)
  end

  def get_bid_from_node(node, order = %Order{}) do
    IO.inspect(node)
    IO.inspect(order)
    GenServer.call({__MODULE__, node}, {:get_bid, order}, @timeout)
  end

  # END User API

  # Server API
  def handle_call({:get_bid, order}, _from, data) do
    IO.inspect(Floor.get())
    IO.inspect(Direction.get())
    cab_state = CabState.new(Floor.get(), Direction.get())

    IO.inspect(Order.can_handle_order?(order, cab_state))
    cost = CostFunction.calculate(order, cab_state)
    IO.inspect(cost)

    {:reply, cost, data}
  end

  # END Server API
end

# BidHandler.get_bids_on_order(Order.new(2,:hall_down))
