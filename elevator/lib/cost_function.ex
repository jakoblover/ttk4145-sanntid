defmodule CostFunction do

  def calculate(order = %Order{}, cab_state = %CabState{}) do
    if Order.can_handle_order?(order, cab_state) do
      0
    else
      1 + calculate(order, cab_state |> CabState.next())
    end
  end
end
