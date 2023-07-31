defmodule Graft.Member do
  @moduledoc false
  alias Graft.Supervisor

  def change(server, serverJoin \\ [], serverLeave \\ []), do
    case {serverJoin, serverLeave}
      {[], []} ->
        IO.puts("No membership change requested.")

      {serverJoin, []} ->
        #start new servers
        Enum.each(serverJoin, fn server ->
          Supervisor.add_server(server)
        end)

        case GenStateMachine.call(server,
        {:entry,
        {:change, %Graft.MemberChangeRPC{
                              server_join: serverJoin,
                              server_leave: []
        }}}) do
          {:ok, response} -> response
          {:error, {:redirect, leader}} -> change(leader, serverJoin, [])
          {:error, msg} -> msg
        end

      {[], serverLeave} ->
        case GenStateMachine.call(server, {:entry, {:change, %Graft.MemberChangeRPC{
          server_join: [],
          server_leave: serverLeave
        }}}) do
          {:ok, response} -> response
          {:error, {:redirect, leader}} -> change(leader, [], serverLeave)
          {:error, msg} -> msg
        end

      {serverJoin, serverLeave} ->
        #start new servers
        Enum.each(serverJoin, fn server ->
          Supervisor.add_server(server)
        end)

        case GenStateMachine.call(server, {:entry, {:change, %Graft.MemberChangeRPC{
          server_join: serverJoin,
          server_leave: serverLeave
        }}}) do
          {:ok, response} -> response
          {:error, {:redirect, leader}} -> change(leader, serverJoin, serverLeave)
          {:error, msg} -> msg
        end

    end
  end

  def cluster_config_info(servers), do
    node_address=elem(hd(Application.fetch_env!(:graft, :cluster)),1)
    Enum.map(servers, fn server -> {server, node_address} end)
  end

end
