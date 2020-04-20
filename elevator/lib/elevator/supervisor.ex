defmodule Elevator.Supervisor do
  use Supervisor

  def start_link(numb, opts) do
    Supervisor.start_link(__MODULE__, numb, opts)
  end

  @doc """
  This is the entry point for the elevator. It starts up the genservers, tasks and agents
  in the children list through this supervisor.
  """
  @impl true
  def init(numb) do
    children = [
      {Driver, [15656 + String.to_integer(numb)]}, # For every elevator on the same computer, we increment the port number
      Poller, # Polls all the buttons on the elevator and communicates with the BidHandler and OrderHandler
      {Watchdog, {6800, "heis" <> numb}}, # Makes sure all orders are completed
      {OrderHandler, "heis" <> numb}, # Handles the request list and order list on the current node
      {Agents.Counter, 0}, # Agent to keep track of how many nodes we have started on our computer
      {Agents.Direction, :stop}, # Agent to keep track of the direction of travel
      {Agents.Floor, 0}, # Agent to keep track of current floor
      {Agents.Door, :closed}, # Agent to keep track of door state
      ElevatorFSM, # Finite State Machine for the elevator
      BidHandler # Communicates with other nodes to facilitate which node gets an order
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5)
  end
end
