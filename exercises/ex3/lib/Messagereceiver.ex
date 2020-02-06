defmodule Udpkom.MessageReceiverUDP do
    use GenServer

    def start_link(opts \\ []) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

    def init (:ok) do
      {:ok, _socket} = :gen_udp.open(20002, [active: true])
    end

    # Handle UDP data
    def handle_info({:udp, _socket, _ip, _port, data}, state) do
      IO.puts(data)
      {:noreply, state}
    end

    # Ignore everything else
    def handle_info({_, _socket}, state) do
      {:noreply, state}
    end
  end


# Port 34933 for fixed size message
# Port 33546 for 0-terminated messages
defmodule Udpkom.MessageReceiverTCP do
  use GenServer

  def start_link(opts \\ []) do
    ip = Application.get_env :tcp_server, :ip, {127,0,0,1}
    port = Application.get_env :tcp_server, :port, 34933
    GenServer.start_link(__MODULE__,[ip,port],[])
  end

  def init [ip,port] do
    IO.inspect "listening"
    {:ok,listen_socket}= :gen_tcp.listen(port,[:binary,{:packet, :raw},{:active,true},{:ip,ip}])
    IO.inspect "accepting"
    {:ok,socket } = :gen_tcp.accept listen_socket
    IO.inspect "accepted"
    {:ok, %{ip: ip,port: port,socket: socket}}
  end

  def handle_info({:tcp,socket,packet},state) do
    IO.inspect packet, label: "incoming packet"
    :gen_tcp.send socket,"Hi Blackode \n"
    {:noreply,state}
  end

  def handle_info({:tcp_closed,socket},state) do
    IO.inspect "Socket has been closed"
    {:noreply,state}
  end

  def handle_info({:tcp_error,socket,reason},state) do
    IO.inspect socket,label: "connection closed dut to #{reason}"
    {:noreply,state}
  end

end

defmodule Udpkom.KVServer do

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    serve(client)
    loop_acceptor(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(line, socket) do
    :gen_tcp.send(socket, line)
  end
end

