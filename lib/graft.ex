defmodule Graft do
  @moduledoc """
  Documentation for Graft.
  """

  def start(servers) do
    Graft.StateFactory.start()
    case servers do
        0 -> :ok
        x ->
            Graft.Server.start
            start(x-1)
    end
  end
end