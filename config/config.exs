# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :mim,
  ecto_repos: [Mim.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

config :mim, :matrix,
  server_name: "localhost",
  client_base_url: nil,
  federation_server: nil,
  federation_port: 8448,
  identity_server_base_url: nil

config :mim, :oidc,
  issuer: nil,
  client_id: nil,
  client_secret: nil,
  scopes: ~w(openid profile email),
  redirect_path: "/_matrix/client/v3/login/sso/callback",
  identity_providers: [
    %{id: "oidc", name: "Continue"}
  ]

# Configures the endpoint
config :mim, MimWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: MimWeb.ErrorHTML, json: MimWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Mim.PubSub,
  live_view: [signing_salt: "Ap4Of2O7"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :mim, Mim.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.25.4",
  mim: [
    args:
      ~w(js/app.js --bundle --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/* --alias:@=.),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "4.1.7",
  mim: [
    args: ~w(
      --input=assets/css/app.css
      --output=priv/static/assets/css/app.css
    ),
    cd: Path.expand("..", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
