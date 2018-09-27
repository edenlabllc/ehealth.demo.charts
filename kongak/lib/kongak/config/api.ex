defmodule Kongak.Api do
  @moduledoc false

  @derive {Jason.Encoder, except: [:plugins]}

  defstruct ~w(
    name
    plugins
    hosts
    methods
    strip_uri
    upstream_url
    uris
    preserve_host
    retries
    upstream_connect_timeout
    upstream_send_timeout
    upstream_read_timeout
    https_only
    http_if_terminated
  )a
end
