defmodule Kongak.Processor.ApiProcessor do
  @moduledoc false

  alias Kongak.Api
  alias Kongak.Config
  alias Kongak.Kong
  alias Kongak.Processor.PluginProcessor
  alias Kongak.Server

  def process(%Config{apis: apis}, %Server{} = server) do
    delete_apis(server, apis)
    create_apis(server, apis)
    update_apis(server, apis)
  end

  defp delete_apis(%Server{apis: server_apis}, apis) do
    server_apis
    |> Enum.map(fn server_api ->
      name = server_api["name"]

      unless Enum.find(apis, &(Map.get(&1, :name) == name)) do
        Kong.delete_api(name)
      end
    end)
  end

  defp create_apis(%Server{apis: server_apis, api_plugins: server_plugins}, apis) do
    apis
    |> Enum.map(fn %Api{name: name} = api ->
      unless Enum.find(server_apis, &(Map.get(&1, "name") == name)) do
        Kong.create(api)
        Enum.map(api.plugins, &Kong.create(api, &1))
      end
    end)
  end

  defp update_apis(%Server{apis: server_apis, api_plugins: server_plugins}, apis) do
    server_apis
    |> Enum.map(fn server_api ->
      name = server_api["name"]

      case Enum.find(apis, &(Map.get(&1, :name) == name)) do
        %Api{} = api ->
          if compare_apis(api, server_api), do: :ok, else: Kong.update(api)
          server_api_plugins = Enum.filter(server_plugins, &(Map.get(&1, "api_id") == server_api["id"]))
          delete_api_plugins(api, server_api_plugins)
          create_and_update_api_plugins(api, server_api_plugins)

        nil ->
          :ok
      end
    end)
  end

  defp create_and_update_api_plugins(%Api{plugins: plugins} = api, server_api_plugins) do
    Enum.map(plugins, fn plugin ->
      case Enum.find(server_api_plugins, &(Map.get(&1, "name") == plugin.name)) do
        nil ->
          Kong.create(api, plugin)

        %{"id" => plugin_id} = server_plugin ->
          if PluginProcessor.compare(plugin, server_plugin), do: :ok, else: Kong.update(api, plugin, plugin_id)
      end
    end)
  end

  defp delete_api_plugins(%Api{plugins: plugins}, server_api_plugins) do
    Enum.map(server_api_plugins, fn server_plugin ->
      case Enum.find(plugins, &(Map.get(&1, :name) == server_plugin["name"])) do
        nil -> Kong.delete_plugin(server_plugin["id"])
        _ -> :ok
      end
    end)
  end

  defp compare_apis(api, server_api) do
    attributes = ~w(
      hosts
      http_if_terminated
      https_only
      name
      preserve_host
      retries
      strip_uri
      methods
      uris
      upstream_connect_timeout
      upstream_read_timeout
      upstream_send_timeout
      upstream_url
    )

    new_api =
      api
      |> Jason.encode!()
      |> Jason.decode!()
      |> Map.take(attributes)
      |> Enum.filter(fn {_, v} -> !is_nil(v) end)

    server_api =
      server_api
      |> Map.take(attributes)
      |> Enum.filter(fn {_, v} -> !is_nil(v) end)

    new_api == server_api
  end
end
