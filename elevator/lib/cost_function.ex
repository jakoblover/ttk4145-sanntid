defmodule CostFunction do
  def calculate(order = %Order{}, cab_state = %CabState{}) do
    # IO.inspect(order)
    # IO.inspect(cab_state)

    if Order.can_handle_order?(order, cab_state) do
      0
    else
      # IO.inspect(1 + calculate(order, cab_state |> CabState.next()))
      1 + calculate(order, cab_state |> CabState.next())
    end
  end
end
