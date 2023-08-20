defmodule Graft.Simulation do
  @moduledoc """
  Simulate Raft event time and analyze the results.
  """

  def start_simulation do
    Graft.Timer.start_coordinator()

    coordinator_pid = Process.whereis(:coordinator)

    member = [:server0, :server9, :server8]
    # , :server8, :server7, :server6

    for _ <- 1..1000 do
      send(coordinator_pid, :initialise_cluster)
      :timer.sleep(1000)
      send(coordinator_pid, :start_graft)
      :timer.sleep(1000)
      send(coordinator_pid, {:add_member, member})
      :timer.sleep(1000)
      send(coordinator_pid, :destroy_cluster)
      :timer.sleep(1000)
    end
      send(coordinator_pid, :stop)
      :timer.sleep(500)

    # #每次引用Graft.Timer.add_member(t)的时候，记录t
    # timestamps = Graft.Record.get_t_values

    # IO.inspect(timestamps)

  end

end
