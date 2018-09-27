defmodule Kongak.Consumer do
  @moduledoc false

  @derive {Jason.Encoder, except: [:credentials]}

  defstruct ~w(username custom_id credentials)a
end
