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
