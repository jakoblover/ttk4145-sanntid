defmodule Udpkom do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Udpkom.MessageReceiver, [])
      #worker(Udpkom.MessageSender, [])
    ]

    #Start the main supervisor, and restart failed children individually
    opts = [strategy: :one_for_one, name: Udpkom.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
