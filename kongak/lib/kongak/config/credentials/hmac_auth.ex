defmodule Kongak.Credentials.HmacAuth do
  @moduledoc false

  @derive {Jason.Encoder, except: [:type]}

  defstruct ~w(type username secret)a
end
