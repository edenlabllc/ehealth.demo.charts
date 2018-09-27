defmodule Kongak.Config do
  @moduledoc """
  Config module
  """

  alias Kongak.Api
  alias Kongak.Certificate
  alias Kongak.Credentials.BasicAuth
  alias Kongak.Credentials.HmacAuth
  alias Kongak.Credentials.JwtAuth
  alias Kongak.Credentials.KeyAuth
  alias Kongak.Credentials.Oauth2
  alias Kongak.Consumer
  alias Kongak.Plugin
  alias Kongak.Target
  alias Kongak.Upstream

  defstruct [:host, :port, :path, :data, :apis, :plugins, :certificates, :upstreams, :consumers]

  @doc """
  Yaml supported only
  """
  def parse(%__MODULE__{path: path} = config) do
    with {:ok, data} <- YamlElixir.read_from_file(path) do
      {:ok,
       %{
         config
         | apis: parse_apis(data),
           plugins: parse_plugins(data),
           certificates: parse_certificates(data),
           upstreams: parse_upstreams(data),
           consumers: parse_consumers(data)
       }}
    end
  end

  def validate_path(%__MODULE__{path: path}) do
    case path do
      nil -> {:error, nil}
      _ -> if File.exists?(path), do: :ok, else: {:error, "File doesn't exist"}
    end
  end

  def parse_apis(data) do
    data
    |> Map.get("apis", [])
    |> Enum.map(fn api ->
      plugins = Enum.map(Map.get(api, "plugins", []), &parse_plugin/1)

      Api
      |> create_struct(api)
      |> Map.put(:plugins, plugins)
    end)
  end

  def parse_plugins(data) do
    data
    |> Map.get("plugins", [])
    |> Enum.map(&create_struct(Plugin, &1))
  end

  def parse_certificates(data) do
    data
    |> Map.get("certificates", [])
    |> Enum.map(&create_struct(Certificate, &1))
  end

  def parse_upstreams(data) do
    data
    |> Map.get("upstreams", [])
    |> Enum.map(fn upstream ->
      targets = Enum.map(Map.get(upstream, "targets", []), &parse_target/1)

      Upstream
      |> create_struct(upstream)
      |> Map.put(:targets, targets)
    end)
  end

  def parse_consumers(data) do
    data
    |> Map.get("consumers", [])
    |> Enum.map(fn consumer ->
      credentials = Map.get(consumer, "credentials")
      credentials = if credentials, do: Enum.map(credentials, &parse_credentials(&1))

      Consumer
      |> create_struct(consumer)
      |> Map.put(:credentials, credentials)
    end)
  end

  def parse_plugin(data), do: create_struct(Plugin, data)
  def parse_target(data), do: create_struct(Target, data)

  def parse_credentials(nil), do: nil
  def parse_credentials(%{"type" => "key-auth"} = data), do: create_struct(KeyAuth, data)
  def parse_credentials(%{"type" => "basic-auth"} = data), do: create_struct(BasicAuth, data)
  def parse_credentials(%{"type" => "oauth2"} = data), do: create_struct(Oauth2, data)
  def parse_credentials(%{"type" => "hmac-auth"} = data), do: create_struct(HmacAuth, data)
  def parse_credentials(%{"type" => "jwt"} = data), do: create_struct(JwtAuth, data)
  def parse_credentials(data), do: raise("Invalid credentials: #{inspect(data)}")

  defp create_struct(name, data) do
    struct(name, Enum.map(data, fn {k, v} -> {String.to_atom(k), v} end))
  end
end
