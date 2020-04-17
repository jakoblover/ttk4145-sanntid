defmodule CostFunction do
  require Order

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
    # cost = abs(order.floor - cab_state.floor)

    cond do
      # cab_state.direction == :stop ->
      #   abs(order.floor - cab_state.floor)

      order.order_type == :hall_up and cab_state.direction == :down ->
        cab_state.floor + order.floor

      order.order_type == :hall_down and cab_state.direction == :up ->
        Order.get_max_floor() - cab_state.floor + (Order.get_max_floor() - order.floor)

      true ->
        abs(order.floor - cab_state.floor)
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
