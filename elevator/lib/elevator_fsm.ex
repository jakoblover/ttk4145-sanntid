defmodule ElevatorFSM do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]
  require Driver
  @top 3
  @bottom 0
  # data = {floor, [{order.floor, order.order_type}]} The contents of the state variable data
  def start_link([]) do
    Process.sleep(500)
    Agents.FSMRestartCounter.set(0)
    floor = Driver.get_floor_sensor_state()
    Driver.set_floor_indicator(floor)

    {:ok, _pid} =
      GenStateMachine.start_link(
        ElevatorFSM,
        {:at_floor, {floor, []}},
        name: __MODULE__
      )
  end

  @doc """
  When the elevator arrives at a floor it will decide if it should open its doors
  and what the next direction it should head in is
  """
  def at_floor(:enter, _, data) do
    floor = elem(data, 0)
    orders = OrderHandler.get_orders()
    data = {floor, orders}
    prev_dir = Agents.Direction.get()

    if floor == :between_floors do
      cond do
        prev_dir == :up ->
          move_up()

        prev_dir == :down ->
          move_down()

        true ->
          IO.puts("No previous direction, defaulting to up")
          move_up()
      end
    else
      Agents.Floor.set(floor)

      if length(orders) == 1 do
        order = elem(Enum.fetch(orders, 0), 1)
        order_floor = order.floor
        order_direction = order.order_type

        cond do
          floor == order_floor ->
            Driver.set_order_button_light(order_direction, floor, :off)
            Driver.set_motor_direction(:stop)
            open_door(order, orders)

          floor < order_floor ->
            move_up()

          floor > order_floor ->
            move_down()
        end
      end

      if length(orders) > 1 do
        for x <- 0..(length(orders) - 1) do
          order = elem(Enum.fetch(orders, x), 1)
          order_floor = order.floor
          order_direction = order.order_type

          cond do
            floor == order_floor && order_direction == :cab ->
              Driver.set_order_button_light(order_direction, floor, :off)
              Driver.set_motor_direction(:stop)
              open_door(order, orders)

            floor == order_floor &&
              (prev_dir == :down or prev_dir == :stop or order_floor == @top) &&
                order_direction == :hall_down ->
              Driver.set_order_button_light(order_direction, floor, :off)
              Driver.set_motor_direction(:stop)
              open_door(order, orders)

            floor == order_floor &&
              (prev_dir == :up or prev_dir == :stop or order_floor == @bottom) &&
                order_direction == :hall_up ->
              :stop
              Driver.set_order_button_light(order_direction, floor, :off)
              Driver.set_motor_direction(:stop)
              open_door(order, orders)

            true ->
              nil
          end

          cond do
            floor < order_floor and (prev_dir == :up or prev_dir == :stop) ->
              move_up()

            floor > order_floor and (prev_dir == :down or prev_dir == :stop) ->
              move_down()

            floor == @bottom and order_direction == :cab and floor < order_floor ->
              move_up()

            floor == @top and order_direction == :cab and floor > order_floor ->
              move_down()

            true ->
              Agents.Direction.set(:stop)
          end
        end
      else
        if Agents.Direction.get() != :stop do
          Driver.set_motor_direction(:stop)
          Agents.Direction.set(:stop)
        end
      end
    end

    {:keep_state, data, [{:state_timeout, 100, :waiting_for_orders}]}
  end

  def at_floor(:state_timeout, :waiting_for_orders, _data) do
    :repeat_state_and_data
  end

  def at_floor(:cast, :up, data) do
    Driver.set_motor_direction(:up)
    Agents.Direction.set(:up)
    {:next_state, :moving_past_floor, data}
  end

  def at_floor(:cast, :down, data) do
    Driver.set_motor_direction(:down)
    Agents.Direction.set(:down)
    {:next_state, :moving_past_floor, data}
  end

  @doc """
  When leaving a floor the elevator will enter this state
  and will stay until the floor sensor registers as between floors
  """
  def moving_past_floor(:enter, _, _data) do
    floor = Driver.get_floor_sensor_state()
    Agents.Door.set(:closed)

    if floor == :between_floors do
      not_at_floor()
    end

    {:keep_state_and_data, [{:state_timeout, 100, :at_floor}]}
  end

  def moving_past_floor(:state_timeout, :at_floor, _data) do
    :repeat_state_and_data
  end

  def moving_past_floor(:cast, :not_at_floor, data) do
    {:next_state, :moving_between_floors, data}
  end

  def moving_past_floor(:cast, _, _data) do
    :repeat_state_and_data
  end

  @doc """
  The elevator will stay in this state until the floor sensor registers as at a floor
  """
  def moving_between_floors(:enter, _, _data) do
    floor = Driver.get_floor_sensor_state()

    if floor != :between_floors do
      at_floor()
    end

    {:keep_state_and_data, [{:state_timeout, 100, :between_floors}]}
  end

  def moving_between_floors(:state_timeout, :between_floors, _data) do
    :repeat_state_and_data
  end

  @doc """
  Turns on the floor indicator and moves to the at_floor state
  """
  def moving_between_floors(:cast, :at_floor, data) do
    floor = Driver.get_floor_sensor_state()
    Driver.set_floor_indicator(floor)
    orders = elem(data, 1)
    data = {floor, orders}
    {:next_state, :at_floor, data}
  end

  def kill_fsm do
    GenStateMachine.stop(__MODULE__, :normal, :infinity)
  end

  def update_orders(new_orders) do
    GenStateMachine.cast(__MODULE__, {:update_orders, new_orders})
  end

  defp move_up do
    GenStateMachine.cast(__MODULE__, :up)
  end

  defp move_down do
    GenStateMachine.cast(__MODULE__, :down)
  end

  defp at_floor do
    GenStateMachine.cast(__MODULE__, :at_floor)
  end

  defp not_at_floor do
    GenStateMachine.cast(__MODULE__, :not_at_floor)
  end

  defp open_door(order, orders) do
    if Agents.Door.get() == :closed do
      IO.inspect("Opening door")
      Driver.set_door_open_light(:on)
      IO.inspect("The current orders are:")

      orders
      |> Enum.map(fn order ->
        IO.inspect(to_string(order.floor) <> " , " <> to_string(order.order_type))
      end)

      Process.sleep(3000)
      OrderHandler.order_handled(order)

      IO.inspect(to_string(order.floor) <> " , " <> to_string(order.order_type),
        label: "Cleared order"
      )

      Agents.Door.set(:open)
      IO.inspect("Closing door")
      Driver.set_door_open_light(:off)
    else
      OrderHandler.order_handled(order)

      IO.inspect(to_string(order.floor) <> " , " <> to_string(order.order_type),
        label: "Cleared order"
      )
    end
  end
end
