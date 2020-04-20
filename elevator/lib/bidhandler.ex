defmodule BidHandler do
  use GenServer
  @timeout 1000

  # Initialization and startup functions

  def start_link([]) do
    GenServer.start_link(__MODULE__, {[], []}, name: __MODULE__)
  end

  def init(_opts) do
    send({:heis1, :"heis1@10.0.0.16"}, node())
    send({:heis2, :"heis2@10.0.0.16"}, node())
    {:ok, []}
  end

  # User API
  def distribute(order) do
    # IO.inspect(OrderHandler.get_orders(), label: "Get")
    bids = get_bids_on_order(order)
    node = get_best_bid(bids)
    # IO.inspect(bids, label: "Bids from nodes")
    # IO.inspect(order, label: "Order getting distributed")
    # IO.inspect(node, label: "Node that got the order")
    OrderHandler.new_order(node, order)
  end

  def get_bids_on_order(order) do
    nodes = Network.all_nodes()
    # IO.inspect(Node.list(), label: "Nodes.list bidhandler")
    # IO.inspect(nodes, label: "Network.all_nodes bidhandler")
    all_bids = nodes |> Enum.map(fn node -> get_bid_from_node(node, order) end)

    all_bids |> Enum.reject(fn bid -> match?({:error, _}, bid) end)
  end

  def get_bid_from_node(node, order = %Order{}) do
    GenServer.call({__MODULE__, node}, {:get_bid, {node, order}}, @timeout)
  end

  def get_best_bid(bids) do
    bids |> Enum.min_by(fn {_k, v} -> v end) |> elem(0)
  end

  # END User API

  # Server API
  def handle_call({:get_bid, {node, order}}, _from, data) do
    # IO.inspect("I am in handle_call")
    cab_state = CabState.new(Agents.Floor.get(), Agents.Direction.get())
    # IO.inspect(cab_state, label: "Cab state is")
    # IO.inspect("Calculating cost")
    cost = {node, CostFunction.calculate(order, cab_state)}
    # IO.inspect(cost, label: "Sending reply")
    {:reply, cost, data}
  end

  # END Server API
end
