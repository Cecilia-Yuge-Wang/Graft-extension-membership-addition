defmodule Graft.Simulation do
  @moduledoc """
  Simulate Raft event.
  """

  def start_simulation do
    Graft.Timer.start_coordinator()

    coordinator_pid = Process.whereis(:coordinator)

    # change the list to change number of server
    member = [:server00]

    # number of simulation
    for _ <- 1..500 do
      send(coordinator_pid, :initialise_cluster)
      :timer.sleep(1000)
      send(coordinator_pid, :start_graft)
      :timer.sleep(1000)
      # i: number of logs
      for i <- 1..10 do
        IO.puts(i)
        send(coordinator_pid, {:request, i})
        :timer.sleep(1000)
      end
      send(coordinator_pid, {:add_member, member})
      :timer.sleep(1000)
      send(coordinator_pid, :destroy_cluster)
      :timer.sleep(1000)
    end
      send(coordinator_pid, :stop)

  end

end
