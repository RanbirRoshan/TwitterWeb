defmodule TwitterWebApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      TwitterWebApp.Repo,
      # Start the endpoint when the application starts
      TwitterWebAppWeb.Endpoint
      # Starts a worker by calling: TwitterWebApp.Worker.start_link(arg)
      # {TwitterWebApp.Worker, arg},
    ]

    {:ok, server_id} = GenServer.start(Twitter, %{})
    Application.put_env(TwitterWebApp, :serverPid, server_id)

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TwitterWebApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    TwitterWebAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
