defmodule Kongak.Credentials.JwtAuth do
  @moduledoc false

  @derive {Jason.Encoder, except: [:type]}

  defstruct ~w(type key algorithm rsa_public_key secret)a
end
