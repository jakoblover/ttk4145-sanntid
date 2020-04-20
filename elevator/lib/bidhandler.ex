defmodule BidHandler do
  use GenServer
  @timeout 1000

  # Initialization and startup functions

  def start_link([]) do
    GenServer.start_link(__MODULE__, {[], []}, name: __MODULE__)
  end

  def init(_opts) do
    {:ok, []}
  end

  ###
  # Server API
  ###

  @doc """
  1. Fetch all the bids on a certain order
  2. Fetch the node with the lowest bid
  3. Add the order to that node
  """
  def distribute(order) do
    bids = get_bids_on_order(order)
    node = get_best_bid(bids)
    # Linjene kommenteres inn for å vise hvordan ordre blir distribuert
    # IO.inspect(bids, label: "Bids from nodes")
    # IO.inspect(order, label: "Order getting distributed")
    # IO.inspect(node, label: "Node that got the order")
    OrderHandler.new_order(node, order)
  end

  @doc """
  Ask all the nodes for a bid on an order. Returns a list of tuples with {node,order}
  """
  def get_bids_on_order(order) do
    nodes = Network.all_nodes()
    all_bids = nodes |> Enum.map(fn node -> get_bid_from_node(node, order) end)

    all_bids |> Enum.reject(fn bid -> match?({:error, _}, bid) end)
  end

  @doc """
  Ask the specified node for a bid on an order
  """
  def get_bid_from_node(node, order = %Order{}) do
    GenServer.call({__MODULE__, node}, {:get_bid, {node, order}}, @timeout)
  end

  @doc """
  From a list of nodes and bids, return the node with the best bid
  """
  def get_best_bid(bids) do
    bids |> Enum.min_by(fn {_k, v} -> v end) |> elem(0)
  end

  ###
  # Server call and cast handles
  ###

  @doc """
  Ask the specified node for a bid on an order.
  """
  def handle_call({:get_bid, {node, order}}, _from, data) do
    cab_state = CabState.new(Agents.Floor.get(), Agents.Direction.get())
    cost = {node, CostFunction.calculate(order, cab_state)}
    {:reply, cost, data}
  end
end
