defmodule Elevator.Supervisor do
  use Supervisor

  def start_link(numb, opts) do
    Supervisor.start_link(__MODULE__, numb, opts)
  end

  @impl true
  def init(numb) do
    children = [
      {Driver, [15656 + String.to_integer(numb)]},
      Poller,
      {Watchdog, {6800, "heis" <> numb}},
      # OrderHandler,
      {OrderHandler, "heis" <> numb},
      {Counter, 0},
      {Direction, :stop},
      ElevatorFSM
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
