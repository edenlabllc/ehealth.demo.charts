defmodule Kongak.Upstream do
  @moduledoc false

  @derive {Jason.Encoder, except: [:targets]}

  defstruct ~w(name slots hash_on hash_fallback hash_on_header hash_fallback_header healthchecks targets)a
end
