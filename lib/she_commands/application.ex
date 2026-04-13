defmodule SheCommands.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SheCommandsWeb.Telemetry,
      SheCommands.Repo,
      {DNSCluster, query: Application.get_env(:she_commands, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SheCommands.PubSub},
      {Task.Supervisor, name: SheCommands.TaskSupervisor},
      # Start to serve requests, typically the last entry
      SheCommandsWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SheCommands.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SheCommandsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
