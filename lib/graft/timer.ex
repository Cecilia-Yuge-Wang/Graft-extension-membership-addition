defmodule Graft.Timer do
  @moduledoc false
  @timer_node :"timer@192.168.0.195"

  def start_coordinator do
    spawn(&coordinator/0)
    |> Process.register(:coordinator)
  end

  # Called from the location below, must be inserted before using the Timer
#  def leader(:cast, :init, data = %Graft.State{log: [{prev_index, _, _} | _]}) do
#    t = :os.system_time(:millisecond)
#    Graft.Timer.elected(t, data.me)
#    Logger.info("New leader: #{inspect(data.me)}.")

  def elected(t, leader) do
    IO.puts("Elected event timestamp: #{t}, leader: #{leader}")
    send({:timer, @timer_node}, {:elected, t, leader})
  end

  def member_added(t) do
    IO.puts("Member added event timestamp: #{t}")
    record_timestamp(t, "member_added_timestamp2.txt")
    send({:timer, @timer_node}, {:member_added, t})
  end

  def record_timestamp(t, filename) do
    with {:ok, file} <- File.open(filename, [:append]),
         :ok <- IO.write(file, "#{inspect(t)}\n"),
         :ok <- File.close(file) do
      :ok
    else
      error -> error
    end
  end

  defp coordinator do
    receive do
      :initialise_cluster ->
        IO.puts("Received :initialise_cluster message")
        initialise_cluster()
        coordinator()

      :destroy_cluster ->
        IO.puts("Received :destroy_cluster message")
        destroy_cluster()
        coordinator()

      {:kill_leader, leader} ->
        kill_leader(leader)
        coordinator()

      :start_graft ->
        IO.puts("Received :start_graft message")
        start_graft()
        coordinator()

      {:add_member, member} ->
        IO.puts("Received :add_member message")
        add_member(member)
        coordinator()

      {:stop_member, member} ->
        IO.puts("Received :stop_member message")
        stop_member(member)
        coordinator()

      :stop ->
        :ok

    end
  end

  defp initialise_cluster do
    Graft.start(nil, nil)
    send({:timer, @timer_node}, {:started, node()})
  end

  defp start_graft do
    Graft.start()
  end

  defp kill_leader(leader) do
    t = :os.system_time(:millisecond)
    Supervisor.terminate_child(Graft.Supervisor, leader)
    send({:timer, @timer_node}, {:killed_leader, t})
  end

  defp destroy_cluster, do: Graft.stop()

  defp add_member(member) do
    t = :os.system_time(:millisecond)
    IO.puts("Add member event timestamp: #{t}")
    Graft.add_member(:server1, member)
    record_timestamp(t, "add_member_timestamp2.txt")
    send({:timer, @timer_node}, {:add_member, t})
  end

  defp stop_member(member) do
    for server <- member do
      Supervisor.terminate_child(Graft.Supervisor, server)
    end
    send({:timer, @timer_node}, {:stopped_member})
  end

end
