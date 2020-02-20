defmodule Leader do
  def start(_type,_args) do
    import Supervisor.Spec, warn: false

    children = [
      {Leader.Elevator, []}
    ]

    #Start the main supervisor, and restart failed children individually
    opts = [strategy: :one_for_one]

    Supervisor.start_link(children, opts)
  end

  # {pid(), :'heis@10.100.23.147'}
end