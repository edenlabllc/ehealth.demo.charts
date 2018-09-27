defmodule Kongak.Credentials.BasicAuth do
  @moduledoc false

  @derive {Jason.Encoder, except: [:type]}

  defstruct ~w(type username password)a
end
