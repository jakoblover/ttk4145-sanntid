defmodule CostFunction do
  require Order

  @doc """
  Calculates the bid each elevator sends back to the node that initiated the bid.
  Elevators standing still with no current orders are prioritized, the rest
  calculate a bid based on what direction they are currently traveling, the number of orders they currently have
  and their distance away from the target floor.
  """
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
