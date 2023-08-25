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

  # record the time when a member is successfully added to the cluster with old logs caught up.
  def member_added(t) do
    # change filename when change simulation variables
    record_timestamp(t, "evaluations/member_added_timestamp.txt")
    send({:timer, @timer_node}, {:member_added, t})
  end

  # save simulation data for the visualization
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
        initialise_cluster()
        IO.puts(":initialise_cluster")
        coordinator()

      :destroy_cluster ->
        destroy_cluster()
        IO.puts(":destroy_cluster")
        coordinator()

      {:kill_leader, leader} ->
        kill_leader(leader)
        coordinator()

      :start_graft ->
        start_graft()
        IO.puts(":start_graft")
        coordinator()

      {:add_member, member} ->
        add_member(member)
        IO.puts(":add_member")
        coordinator()

      {:request, request} ->
        request(request)
        IO.puts(":request")
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

  # record time when a member change request is made.
  defp add_member(member) do
    t = :os.system_time(:millisecond)
    Graft.add_member(:server1, member)
    # change filename when change simulation variables
    record_timestamp(t, "evaluations/add_member_timestamp.txt")
    send({:timer, @timer_node}, {:add_member, t})
  end

  defp request(request) do
    Graft.request(:server1, request)
    send({:timer, @timer_node}, {:request})
  end

end
