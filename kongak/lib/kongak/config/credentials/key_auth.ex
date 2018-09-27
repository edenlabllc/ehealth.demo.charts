defmodule Kongak.Credentials.KeyAuth do
  @moduledoc false

  @derive {Jason.Encoder, except: [:type]}

  defstruct ~w(type key)a
end
