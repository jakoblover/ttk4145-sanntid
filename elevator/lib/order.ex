defmodule Order do
  @order_types [:hall_down, :hall_up, :cab]
  @num_floors 3
  defstruct floor: nil, order_type: nil

  def new(floor, type)
      when type in @order_types and is_integer(floor) do
    %__MODULE__{floor: floor, order_type: type}
  end

  def all_orders(:cab) do
    0..@num_floors |> Enum.map(&new(&1, :cab))
  end

  def all_orders(:hall_up) do
    0..(@num_floors - 1) |> Enum.map(&new(&1, :hall_up))
  end

  def all_orders(:hall_down) do
    1..@num_floors |> Enum.map(&new(&1, :hall_down))
  end

  def all_orders() do
    @order_types |> Enum.map(&all_orders(&1)) |> List.flatten()
  end

  # def can_handle_order?(
  #       %__MODULE__{floor: floor, order_type: order_type},
  #       %CabState{floor: floor, direction: direction}
  #     ) do
  #   IO.inspect(direction)

  #   case direction do
  #     :stop -> true
  #     :down when order_type in [:cab, :hall_down] -> true
  #     :up when order_type in [:cab, :hall_up] -> true
  #     _otherwise -> false
  #   end
  # end

  def can_handle_order?(
        order = %Order{},
        cab_state = %CabState{}
      ) do
    order_type = order.order_type

    case cab_state.direction do
      :stop -> true
      :down when order_type in [:cab, :hall_down] -> true
      :up when order_type in [:cab, :hall_up] -> true
      _otherwise -> false
    end
  end

  # def can_handle_order?(
  #       %__MODULE__{floor: floor_a},
  #       %CabState{floor: floor_b}
  #     ) do
  #   IO.inspect("Feil sted")
  #   false
  # end

  def filter_handleable_orders(orders, cab_state = %CabState{}) do
    orders |> Enum.filter(fn order -> can_handle_order?(order, cab_state) end)
  end
end
