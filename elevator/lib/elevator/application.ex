defmodule Elevator do
  use Application

  @doc """
  This starts up the top-level elevator supervisor, which is found in elevator/supervisor.ex
  """
  @impl true
  def start(_type, args) do
    Elevator.Supervisor.start_link(args, name: Elevator.Supervisor)
  end
end
