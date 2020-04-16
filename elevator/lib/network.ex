defmodule Network do
  def all_nodes do
    # IO.inspect(Node.list())

    case [Node.self() | Node.list()] do
      [:nonode@nohost] -> {:error, :node_not_running}
      nodes -> nodes
    end
  end
end
