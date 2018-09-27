defmodule Kongak.Server do
  @moduledoc """
  Defines current server state
  """
  defstruct apis: [], api_plugins: [], global_plugins: [], certificates: [], upstreams: [], consumers: []
end
