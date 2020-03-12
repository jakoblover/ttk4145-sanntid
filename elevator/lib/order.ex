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
end
