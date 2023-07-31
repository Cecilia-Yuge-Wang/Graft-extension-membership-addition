def leader(
        {:call, from},
        {:entry, entry},
        data = %Graft.State{log: log = [{prev_index, _, _} | _]}
      ) do

    case entry do
      {:change, %Graft.MemberChangeRPC{
        server_join: serverJoin,
        server_leave: serverLeave
      }} ->
        Logger.debug(
        "#{inspect(data.me)} received a member change request from a client! Index of entry: #{prev_index + 1}."
        )

        old_servers = data.servers
        old_new_servers = old_servers ++ serverJoin
        new_servers =
          Enum.filter(old_new_servers, fn serverInfo ->
            serverInfo not in serverleave
          end)

        old_new_cluster = cluster_config_info(old_new_servers)
        new_cluster = cluster_config_info(new_servers)

        requests = Map.put(data.requests, prev_index + 1, from)
        log = [{prev_index + 1, data.current_term,
          {:cluster, %{old_new_servers_count:length(old_new_servers),
          new_servers_count:length(new_servers),
          old_new_cluster: old_new_cluster,
          new_cluster: new_cluster}}
          } | log]

        events =
            for server <- old_new_servers, server !== data.me, data.ready[server] === true do
              {:next_event, :cast, {:send_append_entries, server}}
            end

      _ ->
        Logger.debug(
          "#{inspect(data.me)} received a request from a client! Index of entry: #{prev_index + 1}."
        )

        requests = Map.put(data.requests, prev_index + 1, from)
        log = [{prev_index + 1, data.current_term, entry} | log]

        events =
          for server <- data.servers, server !== data.me, data.ready[server] === true do
            {:next_event, :cast, {:send_append_entries, server}}
          end

    end
        {:keep_state, %Graft.State{data | log: log, requests: requests}, events}

  end

  def leader(
        :cast,
        %Graft.AppendEntriesRPCReply{success: true, last_log_index: lli, from: from},
        data
      )
      when lli === -1 do
    ready = %{data.ready | from => true}
    {:keep_state, %Graft.State{data | ready: ready}, []}
  end

  def leader(
        :cast,
        %Graft.AppendEntriesRPCReply{
          success: true,
          last_log_index: lli,
          last_log_term: llt,
          from: from
        },
        data = %Graft.State{ready: ready, match_index: match_index, log: [{prev_index, _, newest_log_content} | _]}
      ) do
    Logger.debug(
      "#{inspect(data.me)} recceived a SUCCESSFUL AppendEntriesRPCReply from #{inspect(from)}."
    )

    match_index = %{match_index | from => lli}
    ready = %{ready | from => true}
    next_index = %{data.next_index | from => data.next_index[from] + 1}

    events =
      if data.next_index[from] > prev_index do
        [{:next_event, :cast, :ok}]
      else
        [{:next_event, :cast, {:send_append_entries, from}}]
      end

    commit_index =
      if lli > data.commit_index and llt === data.current_term do
        number_of_matches =
          Enum.reduce(match_index, 1, fn {server, index}, acc ->
            if server !== data.me and index >= lli, do: acc + 1, else: acc
          end)

        if number_of_matches > data.server_count / 2, do: lli, else: data.commit_index
      else
        data.commit_index
      end

    case newest_log_content do
      {:cluster,
      %{
        old_new_servers_count: old_new_servers_count,
        new_servers_count: new_servers_count,
        old_new_cluster: old_new_cluster,
        new_cluster: new_cluster
      }} ->
       log = [{prev_index + 1, data.current_term,
               {:cluster,
                %{
                  new_servers_count: new_servers_count,
                  new_cluster: new_cluster
                }
               }} | log]

          {:keep_state,
          %Graft.State{
            data
            | ready: ready,
              next_index: next_index,
              commit_index: commit_index,
              match_index: match_index,
              log: log,
              server_count:old_new_servers_count,
              servers: old_new_cluster

          }, events}

       {:cluster,
          %{new_servers_count:new_servers_count,
          new_cluster: new_cluster}} ->

          {:keep_state,
          %Graft.State{
            data
            | ready: ready,
              next_index: next_index,
              commit_index: commit_index,
              match_index: match_index
              server_count:new_servers_count,
              servers: new_cluster
          }, events}

      _->
          {:keep_state,
          %Graft.State{
            data
            | ready: ready,
              next_index: next_index,
              commit_index: commit_index,
              match_index: match_index
          }, events}
      end
  end

  def leader(:cast, %Graft.AppendEntriesRPCReply{success: false, from: from}, data) do
    Logger.debug(
      "#{inspect(data.me)} (term: #{data.current_term}) received an UNSUCCESSFUL AppendEntriesRPCReply from #{
        inspect(from)
      }."
    )

    next_index = %{data.next_index | from => data.next_index[from] - 1}

    {:keep_state, %Graft.State{data | next_index: next_index},
     [{:next_event, :cast, {:send_append_entries, from}}]}
  end

  def leader(
        :cast,
        {:send_append_entries, to},
        data = %Graft.State{ready: ready, log: log = [{last_index, _, _} | _tail]}
      ) do
    ready = %{ready | to => false}

    entry =
      if (next = data.next_index[to]) > last_index do
        []
      else
        {^next, term, entry} = Enum.reverse(log) |> Enum.at(next)
        [{term, entry}]
      end

    {prev_index, prev_term, _prev_enrty} =
      case log do
        [{0, 0, nil}] -> {0, 0, nil}
        _ -> Enum.reverse(log) |> Enum.at(next - 1)
      end

    rpc = %Graft.AppendEntriesRPC{
      term: data.current_term,
      leader_name: data.me,
      prev_log_index: prev_index,
      prev_log_term: prev_term,
      entries: entry,
      leader_commit: data.commit_index
    }

    Logger.debug(
      "#{inspect(data.me)} is sending an AppendEntriesRPC to #{inspect(to)}. RPC: #{inspect(rpc)}."
    )

    GenStateMachine.cast(to, rpc)

    {:keep_state, %Graft.State{data | ready: ready},
     [{{:timeout, {:heartbeat, to}}, @heartbeat, :send_heartbeat}]}
  end

  def follower(:cast, %Graft.AppendEntriesRPC{term: term, leader_name: leader}, %Graft.State{
    current_term: current_term,
    me: me
  })
  when term < current_term do
Logger.debug(
  "#{inspect(me)} received AE RPC with outdated term. Replying with success: false."
)

reply(:ae, leader, me, current_term, false)
{:keep_state_and_data, []}
end

def follower(
    :cast,
    %Graft.AppendEntriesRPC{
      term: term,
      leader_name: leader,
      prev_log_index: rpc_pli,
      prev_log_term: rpc_plt,
      leader_commit: leader_commit,
      entries: entries
    },
    data = %Graft.State{current_term: current_term, log: log, commit_index: commit_index}
  ) do
resolve_ae = fn log ->
  new_log =
    [{last_new_index, last_new_term, _entry} | _tail] = append_entries(log, entries, rpc_pli)

  commit_index =
    if leader_commit > commit_index,
      do: min(leader_commit, last_new_index),
      else: commit_index

  Logger.debug(
    "#{inspect(data.me)} is appending the new entry. Replying to #{inspect(leader)} with success: true."
  )

  case entries do
    [] -> reply(:ae, leader, data.me, current_term, true)
    {:cluster,
      %{
        old_new_servers_count: old_new_servers_count,
        new_servers_count: new_servers_count,
        old_new_cluster: old_new_cluster,
        new_cluster: new_cluster
      }} ->
        %Graft.State{
          data
          | server_count: old_new_servers_count,
            servers: old_new_servers
        }
        reply(:ae, leader, data.me, current_term, true, last_new_index, last_new_term)
    {:cluster,
      %{new_servers_count:new_servers_count,
        new_cluster: new_cluster}} ->
          %Graft.State{
            data
            | server_count: new_servers_count,
              servers: new_cluster
          }
          reply(:ae, leader, data.me, current_term, true, last_new_index, last_new_term)
    _ -> reply(:ae, leader, data.me, current_term, true, last_new_index, last_new_term)
  end

  {:keep_state,
   %Graft.State{
     data
     | current_term: term,
       log: new_log,
       commit_index: commit_index,
       leader: leader
   }, [{{:timeout, :election_timeout}, generate_time_out(), :begin_election}]}
end

Logger.debug("#{inspect(data.me)} received AppendEntriesRPC from #{inspect(leader)}.")

case Enum.at(Enum.reverse(log), rpc_pli) do
  {^rpc_pli, ^rpc_plt, _entry} ->
    Logger.debug("Matching log")
    resolve_ae.(log)

  _ ->
    Logger.debug(
      "#{inspect(data.me)} did NOT append entry because of bad log. Replying to #{
        inspect(leader)
      } with success: false."
    )

    GenStateMachine.cast(leader, %Graft.AppendEntriesRPCReply{
      term: current_term,
      success: false,
      from: data.me
    })

    {:keep_state_and_data,
     [{{:timeout, :election_timeout}, generate_time_out(), :begin_election}]}
end
end

def follower(:cast, :force_promotion, data) do
{:next_state, :leader, data,
 [{{:timeout, :election_timeout}, :infinity, :ok}, {:next_event, :cast, :init}]}
end
