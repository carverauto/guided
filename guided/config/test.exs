import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The Dockerized Postgres instance already has the AGE extension installed.
# Reuse that database by default so graph queries keep working in tests.
db_username =
  System.get_env("TEST_DATABASE_USERNAME") || System.get_env("DATABASE_USERNAME") || "postgres"

db_password =
  System.get_env("TEST_DATABASE_PASSWORD") || System.get_env("DATABASE_PASSWORD") || "guided"

db_hostname =
  System.get_env("TEST_DATABASE_HOSTNAME") || System.get_env("DATABASE_HOSTNAME") || "localhost"

db_port = System.get_env("TEST_DATABASE_PORT") || System.get_env("DATABASE_PORT") || "5455"
db_name = System.get_env("TEST_DATABASE_NAME") || System.get_env("DATABASE_NAME") || "guided"

db_name =
  case System.get_env("MIX_TEST_PARTITION") do
    nil -> db_name
    partition -> "#{db_name}#{partition}"
  end

config :guided, Guided.Repo,
  username: db_username,
  password: db_password,
  hostname: db_hostname,
  port: String.to_integer(db_port),
  database: db_name,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :guided, GuidedWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "mG44Z9zhZ+IlhRbUyyp1FLYsk7Hn0AE+awAdM69KCoIJfQ7Tkk3jq2aSBOL1Rolu",
  server: false

# In test we don't send emails
config :guided, Guided.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
