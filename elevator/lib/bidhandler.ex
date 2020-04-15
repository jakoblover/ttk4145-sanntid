defmodule BidHandler do
  use GenServer
  @timeout 100

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
    GenServer.call({__MODULE__, node}, {:get_bid, order}, @timeout)
  end

  # END User API

  # Server API
  def handle_call({:get_bid, order}, _from, data) do
    {:reply, CostFunction.calculate(order, %CabState{}), data}
  end

  # END Server API
end
