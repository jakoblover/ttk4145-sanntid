defmodule CostFunction do
  require Order

  def calculate(order = %Order{}, numb_orders, cab_state = %CabState{}) do
    # IO.inspect("Entering calculate")
    # IO.inspect(node, label: "node")

    # try do
    #   IO.inspect(length(OrderHandler.get_orders(node)), label: "There are this many orders")
    # rescue
    #   e in ArgumentError -> IO.inspect(e, label: "Error")
    # end

    cond do
      cab_state.direction == :stop and numb_orders == 0 ->
        # IO.inspect("Cost is 0")
        0

      order.order_type == :hall_up and cab_state.direction == :down ->
        # IO.inspect("Cost up vs down")
        # IO.inspect(cab_state.floor + order.floor, label: "Cost is")
        cab_state.floor + order.floor + numb_orders

      order.order_type == :hall_down and cab_state.direction == :up ->
        # IO.inspect("Cost down vs up")
        # IO.inspect(
        #   Order.get_max_floor() - cab_state.floor + (Order.get_max_floor() - order.floor),
        #   label: "Cost is"
        # )

        Order.get_max_floor() - cab_state.floor + (Order.get_max_floor() - order.floor) +
          numb_orders

      true ->
        # IO.inspect("Cost neutral")
        # IO.inspect(abs(order.floor - cab_state.floor), label: "Cost is")
        abs(order.floor - cab_state.floor) + numb_orders
    end
  end
end
