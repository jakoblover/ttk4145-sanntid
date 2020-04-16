defmodule ElevatorFSM do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]
  require Driver
  @top 3
  @bottom 0
  # data = {floor, [{order_floor, order_type}]}
  # Start the server
  def start_link([]) do
    IO.puts("I am booting")
    Process.sleep(500)
    Counter.set(0)

    {:ok, _pid} =
      GenStateMachine.start_link(
        ElevatorFSM,
        {:at_floor, {Driver.get_floor_sensor_state(), []}},
        name: __MODULE__
      )
  end

  def at_floor(:enter, _, data) do
    floor = elem(data, 0)
    # IO.inspect(floor)ast mon
    Driver.set_floor_indicator(floor)
    orders = OrderHandler.get_orders()
    data = {floor, orders}
    prev_dir = Direction.get()

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
      # IO.inspect("Entering at_floor mode")
      # IO.inspect("Checking for orders")

      # IO.inspect(orders, label: "The current orders are")
      # IO.inspect("Current floor is #{floor}")
      Floor.set(floor)

      if length(orders) > 0 do
        IO.inspect("Executing order")

        for x <- 0..(length(orders) - 1) do
          order = elem(Enum.fetch(orders, x), 1)
          # order_floor = elem(order, 0)
          IO.inspect(orders)
          order_floor = order.floor
          # order_direction = elem(order, 1)
          order_direction = order.order_type

          #  IO.inspect(order_floor, label: "Order_floor is")
          #  IO.inspect(order_direction, label: "Order_direction is")

          cond do
            floor == order_floor && order_direction == :cab ->
              Driver.set_order_button_light(order_direction, floor, :off)
              Driver.set_motor_direction(:stop)
              open_door(order)

            floor == order_floor &&
              (prev_dir == :down or prev_dir == :stop or order_floor == @top) &&
                order_direction == :hall_down ->
              Driver.set_order_button_light(order_direction, floor, :off)
              Driver.set_motor_direction(:stop)
              open_door(order)

            floor == order_floor &&
              (prev_dir == :up or prev_dir == :stop or order_floor == @bottom) &&
                order_direction == :hall_up ->
              Driver.set_order_button_light(order_direction, floor, :off)
              Driver.set_motor_direction(:stop)
              open_door(order)

            true ->
              IO.puts("No match for this floor")
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
              IO.puts("No direction for this value")
              Direction.set(:stop)
              # IO.inspect(prev_dir)
          end
        end
      else
        Driver.set_motor_direction(:stop)
        Direction.set(:stop)
        # IO.inspect("Waiting for new orders")
        # order = Order.new(2, :hall_down)

        # OrderHandler.get_bid_from_node(:"heis1@10.0.0.16", order) #Sender ordre til seg selv, kan få prog til å gå sakte
      end
    end

    {:keep_state, data, [{:state_timeout, 1000, :waiting_for_orders}]}
  end

  def at_floor(:state_timeout, :waiting_for_orders, _data) do
    :repeat_state_and_data
  end

  def at_floor(:cast, :up, data) do
    IO.inspect("Moving upwards")
    Driver.set_motor_direction(:up)
    Direction.set(:up)
    {:next_state, :moving_past_floor, data}
  end

  def at_floor(:cast, :down, data) do
    IO.inspect("Moving downwards")
    Driver.set_motor_direction(:down)
    Direction.set(:down)
    {:next_state, :moving_past_floor, data}
  end

  def moving_past_floor(:enter, _, _data) do
    # IO.inspect("I am moving past a floor")
    # IO.inspect("Checking for orders")
    # orders = OrderHandler.get_orders()
    floor = Driver.get_floor_sensor_state()

    # data = {floor, orders}

    if floor == :between_floors do
      # IO.inspect("Between floors")
      not_at_floor()
    end

    # IO.inspect("Current floor is #{floor}")
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

  def moving_between_floors(:enter, _, _data) do
    # IO.inspect("I am moving between floors")
    # IO.inspect("Checking for orders")
    # orders = OrderHandler.get_orders()
    floor = Driver.get_floor_sensor_state()

    # data = {floor, orders}

    if floor != :between_floors do
      # IO.inspect("I have arrived at a floor")
      at_floor()
    end

    # IO.inspect("Current floor is #{floor}")
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

  defp open_door(order) do
    #    IO.puts("At_floor remove order")
    Driver.set_door_open_light(:on)
    Driver.set_order_button_light(order.order_type, order.floor, :off)
    OrderHandler.order_handled(order)
    Process.sleep(3000)
    Driver.set_door_open_light(:off)
  end
end
