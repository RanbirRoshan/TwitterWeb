defmodule TwitterWebApp.Repo do
  use Ecto.Repo,
    otp_app: :twitterWebApp,
    adapter: Ecto.Adapters.Postgres
end
