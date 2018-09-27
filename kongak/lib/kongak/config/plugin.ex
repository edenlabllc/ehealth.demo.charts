defmodule Kongak.Plugin do
  @moduledoc false

  @derive Jason.Encoder

  defstruct ~w(name config enabled consumer_id)a
end
