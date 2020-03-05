defmodule Poller do
  use Supervisor

  def start_link([]) do
    IO.puts("Starting Poller Supervisor")
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def stop do
    Supervisor.stop(__MODULE__)
  end

  @impl true
  def init([]) do
    IO.puts("Initializing button pollers")

    button_pollers =
      Order.all_orders()
      |> Enum.map(fn order -> Supervisor.child_spec({ButtonPoller, order}, id: order) end)

    IO.puts("Initialized button pollers")
    Supervisor.init(button_pollers, strategy: :one_for_one)
  end
end

defmodule ButtonPoller do
  require Driver
  use Task, restart: :permanent
  @poll_delay 200

  def start_link([]) do
    IO.puts("lol no")
  end

  def start_link(order = %Order{}) do
    IO.puts("Polling button")
    Task.start_link(__MODULE__, :poll, [order, 0])
  end

  def poll(order, prev_state) do
    receive do
    after
      @poll_delay ->
        if Driver.get_order_button_state(order.floor, order.order_type) == 1 do
          IO.puts("Pressed button")
        end

        poll(order, prev_state)
    end
  end
end
