defmodule Kongak.Kong do
  @moduledoc false

  use HTTPoison.Base
  alias Kongak.Api
  alias Kongak.Cache
  alias Kongak.Certificate
  alias Kongak.Consumer
  alias Kongak.Plugin
  alias Kongak.Target
  alias Kongak.Upstream
  require Logger

  @impl true
  def process_url(url) do
    {:ok, %{host: host, port: port}} = Cache.get_config()
    "#{host}:#{port}#{url}"
  end

  @impl true
  def process_request_headers(headers), do: Keyword.put(headers, :"Content-Type", "application/json")

  @impl true
  def request(method, url, body \\ "", headers \\ [], options \\ []) do
    params = if body != "", do: ", params: #{body}", else: ""
    Logger.info("#{method}: #{url}#{params}")
    super(method, url, body, headers, options)
  end

  def list(type, items \\ [], offset \\ nil)

  def list(:api, apis, offset) do
    url = if !offset, do: "/apis", else: "/apis?offset=#{offset}"

    with %HTTPoison.Response{body: body} <- get!(url) do
      case Jason.decode!(body) do
        %{"offset" => offset, "data" => data} -> list(:api, apis ++ data, offset)
        %{"data" => data} -> apis ++ data
      end
    end
  end

  def list(:plugin, plugins, offset) do
    url = if !offset, do: "/plugins", else: "/plugins?offset=#{offset}"

    with %HTTPoison.Response{body: body} <- get!(url) do
      case Jason.decode!(body) do
        %{"offset" => offset, "data" => data} -> list(:plugin, plugins ++ data, offset)
        %{"data" => data} -> plugins ++ data
      end
    end
  end

  def list(:certificate, certificates, offset) do
    url = if !offset, do: "/certificates", else: "/certificates?offset=#{offset}"

    with %HTTPoison.Response{body: body} <- get!(url) do
      case Jason.decode!(body) do
        %{"offset" => offset, "data" => data} -> list(:certificate, certificates ++ data, offset)
        %{"data" => data} -> certificates ++ data
      end
    end
  end

  def list(:upstream, upstreams, offset) do
    url = if !offset, do: "/upstreams", else: "/upstreams?offset=#{offset}"

    with %HTTPoison.Response{body: body} <- get!(url) do
      case Jason.decode!(body) do
        %{"offset" => offset, "data" => data} -> list(:upstream, upstreams ++ data, offset)
        %{"data" => data} -> upstreams ++ data
      end
    end
  end

  def list(:consumer, consumers, offset) do
    url = if !offset, do: "/consumers", else: "/consumers?offset=#{offset}"

    with %HTTPoison.Response{body: body} <- get!(url) do
      case Jason.decode!(body) do
        %{"offset" => offset, "data" => data} -> list(:consumer, consumers ++ data, offset)
        %{"data" => data} -> consumers ++ data
      end
    end
  end

  def list(:target, upstream_id, targets, offset) do
    url =
      if !offset,
        do: "/upstreams/#{upstream_id}/targets",
        else: "/upstreams/#{upstream_id}/targets?offset=#{offset}"

    with %HTTPoison.Response{body: body} <- get!(url) do
      case Jason.decode!(body) do
        %{"offset" => offset, "data" => data} -> list(:target, upstream_id, targets ++ data, offset)
        %{"data" => data} -> targets ++ data
      end
    end
  end

  def create(%Api{} = api) do
    post!("/apis", Jason.encode!(api))
  end

  def create(%Plugin{} = plugin) do
    post!("/plugins", Jason.encode!(plugin))
  end

  def create(%Certificate{} = certificate) do
    post!("/certificates", Jason.encode!(certificate))
  end

  def create(%Upstream{} = upstream) do
    post!("/upstreams", Jason.encode!(upstream))
  end

  def create(%Consumer{username: username, custom_id: custom_id, credentials: credentials} = consumer) do
    post!("/consumers", Jason.encode!(consumer))

    if credentials do
      consumer_name = username || custom_id

      Enum.map(credentials, fn value ->
        post!("/consumers/#{consumer_name}/#{value.type}", Jason.encode!(value))
      end)
    end
  end

  def create(%Api{name: name}, %Plugin{} = plugin) do
    post!("/apis/#{name}/plugins", Jason.encode!(plugin))
  end

  def create(%Upstream{name: name}, %Target{} = target) do
    post!("/upstreams/#{name}/targets", Jason.encode!(target))
  end

  def update(%Api{name: name} = api) do
    patch!("/apis/#{name}", Jason.encode!(api))
  end

  def update(%Upstream{name: name} = upstream) do
    patch!("/upstreams/#{name}", Jason.encode!(upstream))
  end

  def update(%Plugin{} = plugin, plugin_id) do
    patch!("/plugins/#{plugin_id}", Jason.encode!(plugin))
  end

  def update(%Api{name: name}, %Plugin{} = plugin, plugin_id) do
    patch!("/apis/#{name}/plugins/#{plugin_id}", Jason.encode!(plugin))
  end

  def delete_api(name), do: delete!("/apis/#{name}")

  def delete_plugin(id), do: delete!("/plugins/#{id}")

  def delete_certificate(id), do: delete!("/certificates/#{id}")

  def delete_upstream(id), do: delete!("/upstreams/#{id}")

  def delete_consumer(id), do: delete!("/consumers/#{id}")

  def delete_target(%Upstream{name: name}, id), do: delete!("/upstreams/#{name}/targets/#{id}") |> IO.inspect()
end
