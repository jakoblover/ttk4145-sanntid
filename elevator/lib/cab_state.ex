defmodule CabState do
  defstruct floor: nil, direction: nil
  @valid_directions [:down, :up, :stop]

  @doc """
  Creates a new CabState based on floor and current direction
  """
  def new(floor, direction) when direction in @valid_directions and is_integer(floor) do
    %CabState{floor: floor, direction: direction}
  end
end
