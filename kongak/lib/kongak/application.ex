defmodule Kongak.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_, _) do
    import Supervisor.Spec, warn: false
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: Kongak.Worker.start_link(arg)
      worker(Kongak.Cache, [])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Kongak.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
