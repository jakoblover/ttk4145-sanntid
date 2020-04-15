defmodule CabState do

  defstruct floor: nil, direction: nil
  @valid_directions [:down, :up, :idle]
  @max_floor 3

  def new(floor, direction) when direction in @valid_directions and is_integer(floor) do
    %CabState{floor: floor, direction: direction}
  end

  def next(cab_state) do
    with floor <- cab_state.floor,
         direction <- cab_state.direction
    do
      case direction do
        :idle -> cab_state
        :up when floor < @max_floor   -> %{cab_state | floor: floor+1}
        :up when floor == @max_floor  -> %{cab_state | direction: :down}
        :down when floor > 0          -> %{cab_state | floor: floor-1}
        :down when floor == 0         -> %{cab_state | direction: :up}
      end
    end
  end

end
