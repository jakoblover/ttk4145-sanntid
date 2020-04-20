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
      # For every elevator on the same computer, we increment the port number
      {Driver, [15656 + String.to_integer(numb)]},
      # Polls all the buttons on the elevator and communicates with the BidHandler and OrderHandler
      Poller,
      # Makes sure all orders are completed
      {Watchdog, {6800, "heis" <> numb}},
      # Handles the request list and order list on the current node
      {OrderHandler, "heis" <> numb},
      # Agent which makes sure the elevator is only restarted once when a cab order is not cleared in time
      {Agents.FSMRestartCounter, 0},
      # Agent to keep track of the direction of travel
      {Agents.Direction, :stop},
      # Agent to keep track of current floor
      {Agents.Floor, 0},
      # Agent to keep track of door state
      {Agents.Door, :closed},
      # Finite State Machine for the elevator
      ElevatorFSM,
      # Communicates with other nodes to facilitate which node gets an order
      BidHandler
    ]

    Supervisor.init(children, strategy: :one_for_one, max_restarts: 5)
  end
end
