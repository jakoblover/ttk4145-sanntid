defmodule Leader.Elevator do
    use Genserver

    #Client
    def start_link() do
        GenServer.start_link(__MODULE__, [])
    end

    def updatefloor(pid, floor) do
        Genserver.cast(pid, {:updatefloor, floor})
    end

    def view(pid) do
        Genserver.call(pid, :view)
    end

    #Server
    def handle_cast({:updatefloor, floor}, floorlist) do
        updated_floor_list = [floor|floorlist]
        {:noreply, updated_floor_list}
    end

    def handle_call(:view, _from, floorlist) do
        {:reply, floorlist, floorlist}
    end
end