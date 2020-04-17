# TODO:
# Prevent a button hold from sending out 10000 messages, fix the state change logic

defmodule PollerServer do
  use GenServer

  def init([]) do
    {:ok, {[]}}
  end

  def button_pressed(order) do
    # OrderHandler.add_request(order)
    # IO.inspect(Node.list(), label: "node list")
    if order.order_type == :cab do
      OrderHandler.new_order(order)
    else
      BidHandler.distribute(order)
    end
  end
end

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

  def start_link(order = %Order{}) do
    # IO.puts("Starting poller for floor button #{order.floor} of type #{order.order_type}")
    Task.start_link(__MODULE__, :poll, [order, 0])
  end

  def poll(order, prev_state) do
    receive do
    after
      @poll_delay ->
        with sensor_state <- Driver.get_order_button_state(order.floor, order.order_type) do
          cond do
            Driver.get_order_button_state(order.floor, order.order_type) == 1 and prev_state == 0 ->
              # IO.puts("Pressed button #{} type: #{order.order_type}")
              Driver.set_order_button_light(order.order_type, order.floor, :on)
              PollerServer.button_pressed(order)

            # Driver.get_order_button_state(order.floor, order.order_type) == 0 and prev_state == 1 ->
            # IO.puts("Released button")

            true ->
              nil
              # Nothing interesting happens
          end

          poll(order, sensor_state)
        end
    end
  end
end
