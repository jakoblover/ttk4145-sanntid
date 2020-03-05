defmodule ElevatorFSM do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]
  require Driver

  # data = {floor, [{order_floor, order_type}]}
  # Start the server
  def start_link([]) do
    :dets.open_file(:disk_storage, type: :set)
    :dets.insert(:disk_storage, {:elev, [{3, :hall_up}, {1, :cab}, {2, :hall_down}]})

    {:ok, _pid} =
      GenStateMachine.start_link(
        ElevatorFSM,
        {:at_floor,
         {Driver.get_floor_sensor_state(),
          elem(Enum.at(:dets.lookup(:disk_storage, :elev), 0), 1)}},
        name: __MODULE__
      )
  end

  def at_floor(:enter, _, data) do
    floor = elem(data, 0)
    orders = elem(data, 1)
    Driver.set_floor_indicator(floor)
    IO.inspect("Entering at_floor mode")
    IO.inspect("Checking for orders")
    IO.inspect(orders, label: "The current orders are")
    IO.inspect("Current floor is #{floor}")

    if length(orders) > 0 do
      IO.inspect("Executing order")
      [head | _tail] = orders
      current_order = elem(head, 0)
      current_order_direction = elem(head, 1)

      cond do
        floor == current_order ->
          Driver.set_order_button_light(current_order_direction, floor, :off)
          Driver.set_motor_direction(:stop)
          open_door()

        floor < current_order ->
          move_up()

        floor > current_order ->
          move_down()
      end
    else
      IO.inspect("Waiting for new orders")
    end

    {:keep_state_and_data, [{:state_timeout, 1000, :waiting_for_orders}]}
  end

  def at_floor(:state_timeout, :waiting_for_orders, _data) do
    :repeat_state_and_data
  end

  def at_floor(:cast, :up, data) do
    IO.inspect("Moving upwards")
    Driver.set_motor_direction(:up)
    {:next_state, :moving_past_floor, data}
  end

  def at_floor(:cast, :down, data) do
    IO.inspect("Moving downwards")
    Driver.set_motor_direction(:down)
    {:next_state, :moving_past_floor, data}
  end

  def at_floor(:cast, :open_door, data) do
    floor = elem(data, 0)
    orders = elem(data, 1)
    [_head | tail] = orders
    data = {floor, tail}

    IO.inspect(tail, label: "The tail is")
    IO.inspect(data, label: "The data is")
    {:next_state, :door_open, data}
  end

  def at_floor(:cast, {:update_orders, new_orders}, data) do
    floor = elem(data, 0)
    orders = new_orders
    data = {floor, orders}
    :dets.insert(:disk_storage, {:elev, orders})
    {:repeat_state, data}
  end

  def door_open(:enter, _, _data) do
    Driver.set_door_open_light(:on)
    IO.inspect("Opening doors")
    Process.sleep(3000)
    IO.inspect("Closing doors")
    Driver.set_door_open_light(:off)
    at_floor()
    :keep_state_and_data
  end

  def door_open(:state_timeout, :door_open, _data) do
    :repeat_state_and_data
  end

  def door_open(:cast, :at_floor, data) do
    {:next_state, :at_floor, data}
  end

  def door_open(:cast, {:update_orders, new_orders}, data) do
    floor = elem(data, 0)
    orders = new_orders
    data = {floor, orders}
    :dets.insert(:disk_storage, {:elev, orders})
    {:keep_state, data, [{:state_timeout, 100, :door_open}]}
  end

  def moving_past_floor(:enter, _, _data) do
    IO.inspect("I am moving past a floor")
    floor = Driver.get_floor_sensor_state()

    if floor == :between_floors do
      IO.inspect("Between floors")
      not_at_floor()
    end

    IO.inspect("Current floor is #{floor}")
    {:keep_state_and_data, [{:state_timeout, 100, :at_floor}]}
  end

  def moving_past_floor(:state_timeout, :at_floor, _data) do
    :repeat_state_and_data
  end

  def moving_past_floor(:cast, :not_at_floor, data) do
    {:next_state, :moving_between_floors, data}
  end

  def moving_past_floor(:cast, {:update_orders, new_orders}, data) do
    floor = elem(data, 0)
    orders = new_orders
    data = {floor, orders}
    :dets.insert(:disk_storage, {:elev, orders})
    {:keep_state, data, [{:state_timeout, 100, :at_floor}]}
  end

  def moving_between_floors(:enter, _, _data) do
    IO.inspect("I am moving between floors")
    floor = Driver.get_floor_sensor_state()

    if floor != :between_floors do
      IO.inspect("I have arrived at a floor")
      at_floor()
    end

    IO.inspect("Current floor is #{floor}")
    {:keep_state_and_data, [{:state_timeout, 100, :between_floors}]}
  end

  def moving_between_floors(:state_timeout, :between_floors, _data) do
    :repeat_state_and_data
  end

  def moving_between_floors(:cast, :at_floor, data) do
    floor = Driver.get_floor_sensor_state()
    orders = elem(data, 1)
    data = {floor, orders}
    {:next_state, :at_floor, data}
  end

  def moving_between_floors(:cast, {:update_orders, new_orders}, data) do
    floor = elem(data, 0)
    orders = new_orders
    data = {floor, orders}
    :dets.insert(:disk_storage, {:elev, orders})
    {:keep_state, data, [{:state_timeout, 100, :between_floors}]}
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

  defp open_door do
    GenStateMachine.cast(__MODULE__, :open_door)
  end
end
