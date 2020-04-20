defmodule PollerServer do
  use GenServer

  def init([]) do
    {:ok, {[]}}
  end

  @doc """
  Acts as an interface between the button presses and the distribution of orders
  """
  def button_pressed(order) do
    OrderHandler.add_request(order)

    if order.order_type != :cab do
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

  @doc """
  Starts a button poller for each possible button we can press
  """
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
    Task.start_link(__MODULE__, :poll, [order, 0])
  end

  @doc """
  Loop that checks the state of the button, and calls upon the PollerServer.button_pressed(order)
  if a button was pressed.
  """
  def poll(order, prev_state) do
    receive do
    after
      @poll_delay ->
        with sensor_state <- Driver.get_order_button_state(order.floor, order.order_type) do
          cond do
            Driver.get_order_button_state(order.floor, order.order_type) == 1 and prev_state == 0 ->
              PollerServer.button_pressed(order)

            true ->
              nil
          end

          poll(order, sensor_state)
        end
    end
  end
end
