defmodule Udpkom.MessageSenderUDP do
    use Task

    def start_link(opts \\ []) do
        Task.start_link(__MODULE__, :run, opts)
    end

    @spec run :: :ok
    def run() do
        {:ok, socket} = :gen_udp.open(8679)
        :ok = :gen_udp.send(socket, {10,100,23,147}, 20002, "hello")
    end

end

defmodule Udpkom.MessageSenderTCP do
    use Task

    def start_link(opts \\ []) do
        Task.start_link(__MODULE__, :run, opts)
    end

    def run() do
        opts = [
            :binary,
            {:packet, :raw}
        ]

        {:ok, socket} = :gen_tcp.connect({10,100,23,147} , 34933, opts)
        :gen_tcp.send(socket, "hello \n")
    end

end


# defmodule Udpkom.MessageSender do
#   # use GenServer

#   # def start_link(opts \\ []) do
#   #   GenServer.start_link(__MODULE__, :ok, opts)
#   # end

#   def sender() do
#     {:ok, socket} = :gen_udp.open(8679)
#     :ok = :gen_udp.send(socket, {10,100,23,147}, 20002, "hello")
#   end

# end

# defmodule Udpkom.MessageSenderTCP do
#   use GenServer

#   @initial_state %{socket: nil}

#   def start_link do
#     GenServer.start_link(__MODULE__, @initial_state)
#   end

#   def init(state) do
#     opts = [:binary, active: false]
#     {:ok, socket} = :gen_tcp.connect('localhost', 6379, opts)
#     {:ok, %{state | socket: socket}}
#   end
# end
