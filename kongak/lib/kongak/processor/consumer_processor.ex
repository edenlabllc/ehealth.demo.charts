defmodule Kongak.Processor.ConsumerProcessor do
  @moduledoc false

  alias Kongak.Config
  alias Kongak.Consumer
  alias Kongak.Kong
  alias Kongak.Server

  def process(%Config{consumers: consumers}, %Server{} = server) do
    delete(server)
    create(consumers)
  end

  @doc """
  Delete all consumers since we can't identify their credentials
  """
  def delete(%Server{consumers: server_consumers}) do
    Enum.map(server_consumers, &Kong.delete_consumer(Map.get(&1, "id")))
  end

  @doc """
  Create all consumers with their credentials
  """
  def create(consumers) do
    consumers
    |> Enum.map(fn
      %Consumer{username: nil, custom_id: nil} ->
        nil

      %Consumer{} = consumer ->
        Kong.create(consumer)
    end)
  end
end
