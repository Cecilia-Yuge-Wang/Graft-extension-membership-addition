defmodule Graft.AppendEntriesRPC do
  @moduledoc false
            # leader’s term
  defstruct term: -1,
            # so follower can redirect clients
            leader_name: nil,
            # index of log entry immediately preceding new ones
            prev_log_index: -1,
            # term of prevLogIndex entry
            prev_log_term: -1,
            # log entries to store (empty for heartbeat; may send more than one for efficiency)
            entries: [],
            # leader’s commit_index
            leader_commit: -1,
            ########## cluster change
            newest_entry_info: []
end

defmodule Graft.AppendEntriesRPCReply do
  @moduledoc false
            # current_term, for leader to update itself
  defstruct term: -1,
            # true if follower contained entry matching prev_log_index and prev_log_term
            success: false,
            # index of last entry in follower's log
            last_log_index: -1,
            # term of last entry in follower's log
            last_log_term: -1,
            # name of replying server, used to resend new AE with previous entries
            from: nil
end

defmodule Graft.RequestVoteRPC do
  @moduledoc false
            # candidate’s term
  defstruct term: -1,
            # candidate requesting vote
            candidate_name: nil,
            # index of candidate’s last log entry
            last_log_index: -1,
            # term of candidate’s last log entry
            last_log_term: -1
end

defmodule Graft.RequestVoteRPCReply do
  @moduledoc false
            # current_term, for candidate to update itself
  defstruct term: -1,
            # true means candidate received vote
            vote_granted: false
end

################### Member Change #################

defmodule Graft.MemberChangeRPC do
  @moduledoc false
            #0 for C_old_new, 1 for C_new
  defstruct cluster: 0,
            # old_server_count: 0,
            # old_cluster: [],
            # old_new_server_count: 0,
            # old_new_cluster: [],
            new_server_count: 0,
            new_cluster: []
end

# defmodule Graft.AppendMemberChangeEntriesRPC do
#   @moduledoc false
#             # leader’s term
#   defstruct term: -1,
#             # so follower can redirect clients
#             leader_name: nil,
#             # index of log entry immediately preceding new ones
#             prev_log_index: -1,
#             # term of prevLogIndex entry
#             prev_log_term: -1,
#             # log entries to store (empty for heartbeat; may send more than one for efficiency)
#             entries: [],
#             # number of servers in the cluster
#             server_count: 0,
#             # names of each server in the cluster
#             servers: []

# end

# defmodule Graft.AppendMemberChangeEntriesRPCReply do
#   @moduledoc false
#             # current_term, for leader to update itself
#   defstruct term: -1,
#             # true if follower contained entry matching prev_log_index and prev_log_term
#             success: false,
#             # index of last entry in follower's log
#             last_log_index: -1,
#             # term of last entry in follower's log
#             last_log_term: -1,
#             # name of replying server, used to resend new AE with previous entries
#             from: nil
#             server_count:0
#             servers: []
# end
