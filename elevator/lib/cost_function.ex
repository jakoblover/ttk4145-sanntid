defmodule CostFunction do
  require Order

  def calculate(order = %Order{}, cab_state = %CabState{}) do
    numb_orders = length(OrderHandler.get_orders())

    cond do
      cab_state.direction == :stop and numb_orders == 0 ->
        0

      order.order_type == :hall_up and cab_state.direction == :down ->
        cab_state.floor + order.floor + numb_orders

      order.order_type == :hall_down and cab_state.direction == :up ->
        Order.get_max_floor() - cab_state.floor + (Order.get_max_floor() - order.floor) +
          numb_orders

      true ->
        abs(order.floor - cab_state.floor) + numb_orders
    end
  end
end
