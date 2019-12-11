# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :twitterWebApp,
  ecto_repos: [TwitterWebApp.Repo]

# Configures the endpoint
config :twitterWebApp, TwitterWebAppWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "H4HozGjzzPpfRRkUjJf+O0jIIzO3s9c14UI/U61anbUrZHlofH4hPlbh+xw5Fgps",
  render_errors: [view: TwitterWebAppWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: TwitterWebApp.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
