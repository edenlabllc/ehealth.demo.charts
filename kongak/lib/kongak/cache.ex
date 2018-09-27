defmodule Kongak.Cache do
  @moduledoc false

  use Agent

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_config do
    Agent.get(__MODULE__, &{:ok, Map.get(&1, :config)})
  end

  def set_config(config) do
    Agent.update(__MODULE__, &Map.put(&1, :config, config))
  end
end
