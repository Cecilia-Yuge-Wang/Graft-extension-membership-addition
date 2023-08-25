defmodule Graft do
  @moduledoc """
  An API of the raft consensus algorithm, allowing for custom client requests
  and custom replicated state machines.

  ## Example

  Let's create a distributed stack. The first step is to set up the state machine.
  Here we will use the `Graft.Machine` behaviour.

  ```
  defmodule MyStackMachine do
      use Graft.Machine

      @impl Graft.Machine
      def init([]) do
          {:ok, []}
      end

      @impl Graft.Machine
      def handle_entry({:put, value}, state) do
          {:ok, [value | state]}
      end

      def handle_entry(:pop, []) do
          {:noop, []}
      end

      def handle_entry(:pop, [response | state]) do
          {response, state}
      end

      def handle_entry(_, state) do
          {:invalid_request, state}
      end
  end
  ```

  Now that we have our state machine, we can define the servers that
  will make up the raft cluster. Each server must have a unique name.

  ```
  servers = [:server1, :server2, :server3]
  ```

  With both the servers and state machine, we can now run the graft funtion,
  which will start the servers and the consensus algorithm.

  ```
  {:ok, supervisor} = Graft.start servers, MyStackMachine
  ```

  `Graft.start` returns the supervisor pid from which we can terminate or restart
  the servers.

  We can now use `Graft.request` to make requests to our consensus cluster.
  As long as we know at least one server, we can send requests, since the `Graft.Client`
  module will forward the request if the server we choose is not the current leader.

  ```
  Graft.request :server1, :pop
  #=> :noop

  Graft.request :server1, {:put, :foo}
  #=> :ok

  Graft.request :server1, :pop
  #=> :foo

  Graft.request :server1, :bar
  #=> :invalid_request
  ```

  That completes the distributed stack.
  """

  use Application

  def start(), do:
    for(
      server <- Application.fetch_env!(:graft, :cluster),
      do: GenStateMachine.cast(server, :start)
    )

  def start(_type, _args), do: Graft.Supervisor.start_link()
  def stop(), do: Supervisor.stop(Graft.Supervisor)

  def leader(server), do: GenStateMachine.call(server, :leader)
  def stop_server(server), do: Supervisor.terminate_child(Graft.Supervisor, server)
  def restart_server(server), do: Supervisor.restart_child(Graft.Supervisor, server)

  @doc """
  Print out the internal state of the `server`.
  """
  def data(server), do: :sys.get_state(server)

  @doc """
  Make a new client request to a server within the consensus cluster.

  `server` - name of the server the request should be sent to.
  `entry`  - processed and applied by the replicated state machine.
  """
  @spec request(atom(), any()) :: response :: any()
  def request(server, entry), do: Graft.Client.request(server, entry)

  ################ Membership addition ##########################
  @doc """
  Make a new add member request to a server within the consensus cluster.

  `server` - name of the server the request should be sent to.
  `serverJoin`  - List of server names(atoms) to join the cluster.
  """
  def add_member(server, serverJoin) do
    case serverJoin do
      [] ->
        IO.puts("No membership change requested.")
      serverJoin ->
        request(server, {:change, {serverJoin, []}})
        request(server, {:change, :C_new})
    end
  end

  @doc """
  To do the simulation of the add member extension
  """
  def simulation(), do: Graft.Simulation.start_simulation

  @doc """
  To get the runtime it takes for the cluster to add new server and replicate all the old log
  """
  # change filenames to record data from every simulation seperately
  def get_time(), do: Graft.Processor.process_files("member_added_timestamp.txt", "add_member_timestamp.txt", "output_5server_15log.txt")


  ##### Planned to do the server leaving part but not finished, part of future work ######

  # ServerJoin = [:server1,...], ServerLeave = [:server1,...]
  # def change_member(server, serverJoin \\ [], serverLeave \\ []) do
  #   case {serverJoin, serverLeave} do
  #     {[], []} ->
  #       IO.puts("No membership change requested.")
  #     {serverJoin, []} ->
  #       add_member(server, serverJoin)
  #     {[], serverLeave} ->
  #       delete_member(server, serverLeave)
  #     {serverJoin, serverLeave} ->
  #       request(server, {:change, {serverJoin, []}})
  #       request(server, {:change, {[], serverLeave}})
  #   end
  # end

  # def delete_member(server, serverLeave) do
  #   case serverLeave do
  #     [] ->
  #       IO.puts("No membership change requested.")
  #     serverLeave ->
  #       request(server, {:change, :C_old_new})
  #       request(server, {:change, {[], serverLeave}})
  #   end
  # end

end
