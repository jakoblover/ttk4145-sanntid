# defmodule Fsm do
#  use GenServer
#  require driver_elixir

#  def start do
#  {:ok, driver_pid} = Driver.start()
#  end

#  def statemachine() do
#    case Driver.get_floor_sensor_state do
#      1 -> Driver.set_motor_direction(driver_pid, :up)
#      2 -> Driver.set_motor_direction(driver_pid, :down)
#    end 

#   end

# end
