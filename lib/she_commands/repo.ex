defmodule SheCommands.Repo do
  use Ecto.Repo,
    otp_app: :she_commands,
    adapter: Ecto.Adapters.Postgres
end
