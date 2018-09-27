defmodule Kongak.Credentials.Oauth2 do
  @moduledoc false

  @derive {Jason.Encoder, except: [:type]}

  defstruct ~w(type name client_id client_secret redirect_uri)a
end
