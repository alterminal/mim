import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :mim, Mim.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "mim_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mim, MimWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "joolCosbnnvK5Xr+O8ww0h/9tB2RM88+vazBxVZCSgLk9MF53wbIosdPtdpmju8r",
  server: false

# In test we don't send emails
config :mim, Mim.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :mim, :matrix,
  server_name: "localhost",
  client_base_url: "http://localhost:4002",
  federation_server: "localhost",
  federation_port: 8448,
  identity_server_base_url: nil

config :mim, :oidc,
  issuer: "https://idp.example.com",
  client_id: "mim-test",
  client_secret: "test-secret",
  scopes: ~w(openid profile email),
  redirect_uri: "http://localhost:4002/_matrix/client/v3/login/sso/callback",
  identity_providers: [
    %{id: "oidc", name: "Continue with OIDC"}
  ]

config :mim, :well_known_req_options, plug: {Req.Test, Mim.WellKnown.HTTP}

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
