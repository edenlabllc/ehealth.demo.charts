defmodule Kongak.Processor.PluginProcessor do
  @moduledoc false

  alias Kongak.Config
  alias Kongak.Kong
  alias Kongak.Plugin
  alias Kongak.Server

  def process(%Config{plugins: plugins}, %Server{} = server) do
    delete(server, plugins)
    create(server, plugins)
    update(server, plugins)
  end

  defp delete(%Server{global_plugins: server_plugins}, plugins) do
    server_plugins
    |> Enum.map(fn plugin ->
      name = plugin["name"]

      unless Enum.find(plugins, &(Map.get(&1, :name) == name)) do
        Kong.delete_plugin(plugin["id"])
      end
    end)
  end

  defp create(%Server{global_plugins: server_plugins}, plugins) do
    plugins
    |> Enum.map(fn %Plugin{name: name} = plugin ->
      unless Enum.find(server_plugins, &(Map.get(&1, "name") == name)) do
        Kong.create(plugin)
      end
    end)
  end

  defp update(%Server{global_plugins: server_plugins}, plugins) do
    server_plugins
    |> Enum.map(fn server_plugin ->
      name = server_plugin["name"]

      case Enum.find(plugins, &(Map.get(&1, :name) == name)) do
        %Plugin{} = plugin ->
          if compare(plugin, server_plugin), do: :ok, else: Kong.update(plugin, server_plugin["id"])

        nil ->
          :ok
      end
    end)
  end

  def compare(plugin, server_plugin) do
    attributes = ~w(name config enabled consumer_id)

    new_plugin =
      plugin
      |> Jason.encode!()
      |> Jason.decode!()
      |> Map.take(attributes)
      |> Enum.filter(fn {_, v} -> !is_nil(v) end)

    server_plugin =
      server_plugin
      |> Map.take(attributes)
      |> Enum.filter(fn {_, v} -> !is_nil(v) end)

    new_plugin == server_plugin
  end
end
