defmodule CostFunction do
  def calculate(order = %Order{}, cab_state = %CabState{}) do
    # IO.inspect(order)
    # IO.inspect(cab_state)

    # if Order.can_handle_order?(order, cab_state) do
    #   0
    # else
    #   IO.inspect(1 + calculate(order, CabState.next(cab_state)))
    #   1 + calculate(order, CabState.next(cab_state))
    # end
    # cost = 0
    cost = abs(order.floor - cab_state.floor)

    cond do
      cab_state.direction == :stop ->
        cost - 1

      order.order_type == :hall_up and cab_state.direction == :down ->
        (cost + 1) * 2

      order.order_type == :hall_down and cab_state.direction == :up ->
        (cost + 1) * 2

      true ->
        cost
    end

    # cost += abs(order.floor - cab_state.floor)

    # if order.floor == cab_state.floor do
    #   0
    # else
    #   IO.inspect(1 + calculate(order, CabState.next(cab_state)))
    #   1 + calculate(order, CabState.next(cab_state))
    # end
  end
end
