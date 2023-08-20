import Config

config :graft,
  cluster: [
    {:server1, :"nonode@nohost"},
    {:server2, :"nonode@nohost"},
    {:server3, :"nonode@nohost"},
    {:server4, :"nonode@nohost"},
    {:server5, :"nonode@nohost"}
    # ,{:server6, :"nonode@nohost"},
    # {:server7, :"nonode@nohost"},
    # {:server8, :"nonode@nohost"},
    # {:server9, :"nonode@nohost"},
    # {:server0, :"nonode@nohost"}
  ],
  machine: MySumMachine,
  machine_args: [],
  server_timeout: fn -> :rand.uniform(51)+149 end,
  heartbeat_timeout: 75

config :logger, :console,
  colors: [info: :green],
  level: :notice
