# def follower(:cast, %Graft.AppendEntriesRPC{term: term, leader_name: leader}, %Graft.State{
#   current_term: current_term,
#   me: me
# })
# when term < current_term do
# Logger.debug(
# "#{inspect(me)} received AE RPC with outdated term. Replying with success: false."
# )

# reply(:ae, leader, me, current_term, false)
# {:keep_state_and_data, []}
# end

# def follower(
#   :cast,
#   %Graft.AppendEntriesRPC{
#     term: term,
#     leader_name: leader,
#     prev_log_index: rpc_pli,
#     prev_log_term: rpc_plt,
#     leader_commit: leader_commit,
#     entries: entries,
#     newest_entry_info: newest_entry_info
#   },
#   data = %Graft.State{current_term: current_term, log: log, commit_index: commit_index}
# ) do
# resolve_ae = fn log ->
#   new_log =
#     [{last_new_index, last_new_term, _entry} | _tail] = append_entries(log, entries, rpc_pli)

#   commit_index =
#     if leader_commit > commit_index,
#       do: min(leader_commit, last_new_index),
#       else: commit_index

#   Logger.debug(
#     "#{inspect(data.me)} is appending the new entry. Replying to #{inspect(leader)} with success: true."
#   )

#   case entries do
#     [] -> reply(:ae, leader, data.me, current_term, true)
#     _ -> reply(:ae, leader, data.me, current_term, true, last_new_index, last_new_term)
#   end

#   {servers, server_count} =
#     case newest_entry_info do
#       {:change, %Graft.MemberChangeRPC{
#         cluster: cluster,
#         new_server_count: new_server_count,
#         new_cluster: new_cluster
#       }} ->
#         if data.servers != new_cluster do
#           if cluster == 0 do
#             # IO.puts("Follower #{inspect(data.me)} is appending the C_old_new change")
#             Logger.debug(
#               "#{inspect(data.me)} is appending the C_old_new change. Replying to #{inspect(leader)} with success: true."
#             )
#           else
#             # IO.puts("Follower #{inspect(data.me)} is appending the C_new change")
#             Logger.debug(
#               "#{inspect(data.me)} is appending the C_new change. Replying to #{inspect(leader)} with success: true."
#             )
#           end
#           {new_cluster, new_server_count}
#         else
#           {data.servers, data.server_count}
#         end
#       _ ->
#         {data.servers, data.server_count}
#     end

#   {:keep_state,
#   %Graft.State{
#     data
#     | current_term: term,
#       log: new_log,
#       commit_index: commit_index,
#       leader: leader,
#       servers: servers,
#       server_count: server_count
#   }, [{{:timeout, :election_timeout}, generate_time_out(), :begin_election}]}
# end

# Logger.debug("#{inspect(data.me)} received AppendEntriesRPC from #{inspect(leader)}.")

# case Enum.at(Enum.reverse(log), rpc_pli) do
# {^rpc_pli, ^rpc_plt, _entry} ->
#   Logger.debug("Matching log")
#   resolve_ae.(log)

# _ ->
#   Logger.debug(
#     "#{inspect(data.me)} did NOT append entry because of bad log. Replying to #{
#       inspect(leader)
#     } with success: false."
#   )

#   GenStateMachine.cast(leader, %Graft.AppendEntriesRPCReply{
#     term: current_term,
#     success: false,
#     from: data.me
#   })

#   {:keep_state_and_data,
#    [{{:timeout, :election_timeout}, generate_time_out(), :begin_election}]}
# end
# end

# def reply(:ae, to, from, term, success, non_voting) do
#   Logger.debug(
#     "#{inspect(from)} is sending AE RPC REPLY to #{inspect(to)} with success: #{
#       inspect(success)
#     } and term: #{inspect(term)}."
#   )

#   GenStateMachine.cast(to, %Graft.AppendEntriesRPCReply{
#     term: term,
#     success: success,
#     from: from,
#     non_voting: non_voting

#   })
# end

# def reply(:ae, to, from, term, success, lli, llt, non_voting) do
#   GenStateMachine.cast(to, %Graft.AppendEntriesRPCReply{
#     term: term,
#     success: success,
#     last_log_index: lli,
#     last_log_term: llt,
#     from: from,
#     non_voting: non_voting
#   })
# end
