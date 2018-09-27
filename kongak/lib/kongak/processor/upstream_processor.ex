defmodule Kongak.Processor.UpstreamProcessor do
  @moduledoc false

  alias Kongak.Config
  alias Kongak.Kong
  alias Kongak.Server
  alias Kongak.Upstream

  def process(%Config{upstreams: upstreams}, %Server{} = server) do
    delete(server, upstreams)
    create(server, upstreams)
    update(server, upstreams)
  end

  defp delete(%Server{upstreams: server_upstreams}, upstreams) do
    server_upstreams
    |> Enum.map(fn server_upstream ->
      name = server_upstream["name"]

      unless Enum.find(upstreams, &(Map.get(&1, :name) == name)) do
        Kong.delete_upstream(server_upstream["id"])
      end
    end)
  end

  defp create(%Server{upstreams: server_upstreams}, upstreams) do
    upstreams
    |> Enum.map(fn %Upstream{name: name} = upstream ->
      unless Enum.find(server_upstreams, &(Map.get(&1, "name") == name)) do
        Kong.create(upstream)
        Enum.map(upstream.targets, &Kong.create(upstream, &1))
      end
    end)
  end

  defp update(%Server{upstreams: server_upstreams}, upstreams) do
    server_upstreams
    |> Enum.map(fn server_upstream ->
      name = server_upstream["name"]

      case Enum.find(upstreams, &(Map.get(&1, :name) == name)) do
        %Upstream{} = upstream ->
          if compare(upstream, server_upstream), do: :ok, else: Kong.update(upstream)
          server_upstream_targets = Kong.list(:target, server_upstream["id"], [], nil)
          delete_upstream_targets(upstream, server_upstream_targets)
          create_and_update_upstream_targets(upstream, server_upstream_targets)

        nil ->
          :ok
      end
    end)
  end

  defp delete_upstream_targets(%Upstream{targets: targets} = upstream, server_upstream_targets) do
    Enum.map(server_upstream_targets, fn server_upstream_target ->
      case Enum.find(targets, &(Map.get(&1, :target) == server_upstream_target["target"])) do
        nil -> Kong.delete_target(upstream, server_upstream_target["id"])
        _ -> :ok
      end
    end)
  end

  defp create_and_update_upstream_targets(%Upstream{targets: targets} = upstream, server_upstream_targets) do
    Enum.map(targets, fn target ->
      case Enum.find(server_upstream_targets, &(Map.get(&1, "target") == target.target)) do
        nil ->
          Kong.create(upstream, target)

        server_target ->
          if compare_target(target, server_target), do: :ok, else: Kong.create(upstream, target)
      end
    end)
  end

  defp compare(upstream, server_upstream) do
    attributes = ~w(
      name
      hash_on
      hash_fallback
      hash_on_header
      hash_fallback_header
      hash_on_cookie
      hash_on_cookie_path
      healthchecks
      slots
    )

    new_upstream =
      upstream
      |> Jason.encode!()
      |> Jason.decode!()
      |> Map.take(attributes)
      |> Enum.filter(fn {_, v} -> !is_nil(v) end)

    server_upstream =
      server_upstream
      |> Map.take(attributes)
      |> Enum.filter(fn {_, v} -> !is_nil(v) end)

    new_upstream == server_upstream
  end

  defp compare_target(target, server_target) do
    attributes = ~w(target weight)

    new_target =
      target
      |> Jason.encode!()
      |> Jason.decode!()
      |> Map.take(attributes)
      |> Enum.filter(fn {_, v} -> !is_nil(v) end)

    server_target =
      server_target
      |> Map.take(attributes)
      |> Enum.filter(fn {_, v} -> !is_nil(v) end)

    new_target == server_target
  end
end
