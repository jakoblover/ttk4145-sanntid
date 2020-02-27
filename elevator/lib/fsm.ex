defmodule ElevatorFSM do
  use GenStateMachine, callback_mode: :state_functions
  require Driver

  # data = [at_floor,stop_btn,moving,door_open]
  # Start the server
  def start_link([]) do
    {:ok, pid} = GenStateMachine.start_link(ElevatorFSM, {:idle, [1, 0, 0, 0]}, name: __MODULE__)
  end

  def idle(:cast, :up, data) do
    IO.inspect("Starting movement")
    Driver.set_motor_direction(:up)
    {:next_state, :moving_past_floor, data}
  end

  def idle(:cast, :open_door, data) do
    IO.inspect("Opening doors")
    {:next_state, :door_open, data}
  end

  def idle(:cast, :emergency, data) do
    IO.inspect("Entering emergency state")
    {:next_state, :emergency_at_floor, data}
  end

  def emergency_at_floor(:cast, :emergency, data) do
    IO.inspect("Emergency state at floor, opening doors")
    {:keep_state, :emergency_at_floor, data}
  end

  def door_open(:cast, :close_door, data) do
    IO.inspect("Closing doors")
    {:next_state, :idle, data}
  end

  def moving_past_floor(:cast, :at_floor, data) do
    if Enum.at(data, 0) == 1 do
      IO.inspect("I am moving past a floor")
      {:next_state, :moving_between_floors, [0, 0, 0, 0]}
    else
      IO.inspect("I am arriving at a floor")
      {:next_state, :idle, [1, 0, 0, 0]}
    end
  end

  def moving_between_floors(:cast, :at_floor, data) do
    IO.inspect("I am moving between floors")
    {:next_state, :moving_past_floor, data}
  end

  def move_up do
    GenStateMachine.cast(__MODULE__, :up)
  end

  def move_down do
    GenStateMachine.cast(__MODULE__, :down)
  end

  def at_floor do
    GenStateMachine.cast(__MODULE__, :at_floor)
  end

  def not_at_floor do
    GenStateMachine.cast(__MODULE__, :not_at_floor)
  end

  def open_door do
    GenStateMachine.cast(__MODULE__, :open_door)
  end

  def close_door do
    GenStateMachine.cast(__MODULE__, :close_door)
  end

  def emeregency do
    GenStateMachine.cast(__MODULE__, :emergency)
  end

  def test1(data1) do
    if(Enum.at(data1, 1) == 0, do: IO.inspect(Enum.at(data1, 1)))
  end
end
