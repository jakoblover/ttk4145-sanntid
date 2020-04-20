defmodule Main do

  @doc """
  Initializes two simulators and two nodes in a 2x2 tmux environment.
  """
  def main(args) do
    i = hd(args)

    cond do
      i == "0" ->
        System.cmd("tmux", [
          "new-session",
          "-d",
          "-s",
          "my_session"
        ])

        System.cmd("tmux", ["split-window", "-h"])
        System.cmd("tmux", ["split-window", "-d"])
        System.cmd("tmux", ["split-window", "-t", ":0.0", "-d"])
        System.cmd("tmux", ["split-window", "-t", ":0.1", "-d"])

        System.cmd("tmux", ["select-layout", "tiled"])

        System.cmd("gnome-terminal", ["--full-screen", "--", "tmux", "attach"])

        Process.sleep(500)

        System.cmd("tmux", [
          "send-keys",
          "-t",
          ":0.4",
          "cd /home/jacob/Documents/Sanntid",
          "Enter"
        ])

        System.cmd("tmux", [
          "send-keys",
          "-t",
          ":0.1",
          "/home/jacob/Documents/Sanntid/SimElevatorServer --port 15657",
          "Enter"
        ])

        System.cmd("tmux", [
          "send-keys",
          "-t",
          ":0.3",
          "/home/jacob/Documents/Sanntid/SimElevatorServer --port 15658",
          "Enter"
        ])

        Process.sleep(100)

        System.cmd("tmux", [
          "send-keys",
          "-t",
          ":0.0",
          "./elevator 1",
          "Enter"
        ])

      i == "1" ->
        Application.start(Elevator, :temporary)
        Elevator.start(:normal, i)

        System.cmd("tmux", [
          "send-keys",
          "-t",
          ":0.2",
          "./elevator 2",
          "Enter"
        ])

        waiter()

      i == "2" ->
        Application.start(Elevator, :temporary)
        Elevator.start(:normal, i)

        waiter()
    end
  end

  def waiter() do
    waiter()
  end
end
