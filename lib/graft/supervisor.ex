defmodule Graft.Supervisor do
  @moduledoc false
  require Logger
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, cluster_config(), name: __MODULE__)
  end

  def init([{my_servers, all_servers}, machine_module, machine_args]) do
    Logger.info("This is node #{node()}, servers on this node are #{inspect(my_servers)}")

    children =
      for {name, _node} <- my_servers do
        worker(Graft.Server, [name, all_servers, machine_module, machine_args], restart: :transient, id: name)
      end

    supervise(children, strategy: :one_for_one)
  end

  def add_server(name, all_servers, machine_module, machine_args) do
    Logger.info("Adding server #{name} to the cluster")

    Supervisor.start_child(__MODULE__, [name, all_servers, machine_module, machine_args])

    new_servers = all_servers ++ [{name, node()}]
    Supervisor.restart_child(__MODULE__, {__MODULE__, {new_servers, all_servers}, machine_module, machine_args})

    Logger.info("Server #{name} added to the cluster")
  end

  defp cluster_config() do
    [
      Application.fetch_env!(:graft, :cluster) |> on_my_node(),
      Application.fetch_env!(:graft, :machine),
      Application.fetch_env!(:graft, :machine_args)
    ]
  end

  defp on_my_node(servers) do
    {(servers |> Enum.group_by(fn {_, node} -> node end))[node()], servers}
  end
end
