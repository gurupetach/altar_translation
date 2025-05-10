defmodule Altar.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AltarWeb.Telemetry,
      Altar.Repo,
      {DNSCluster, query: Application.get_env(:altar, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Altar.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Altar.Finch},
      # Start a worker by calling: Altar.Worker.start_link(arg)
      # {Altar.Worker, arg},
      # Start to serve requests, typically the last entry
      AltarWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Altar.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AltarWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
