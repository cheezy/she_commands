import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :she_commands, SheCommands.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "she_commands_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :she_commands, SheCommandsWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "79o2PKiCGaL4UxmdlAInTcKWcNmwUuzU4Zz7VMGeig/dUI8/gHO8oSv7+7fuoR66",
  server: false

# In test we don't send emails
config :she_commands, SheCommands.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Use Req.Test plug for Claude API in tests
config :she_commands, :claude_req_options, plug: {Req.Test, SheCommands.Chat.ClaudeClient}
config :she_commands, :anthropic_api_key, "test-api-key"

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
