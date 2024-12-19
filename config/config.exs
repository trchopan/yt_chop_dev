# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :yt_chop_dev,
  ecto_repos: [YtChopDev.Repo],
  generators: [timestamp_type: :utc_datetime, binary_id: true]

# Configures the endpoint
config :yt_chop_dev, YtChopDevWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: YtChopDevWeb.ErrorHTML, json: YtChopDevWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: YtChopDev.PubSub,
  live_view: [signing_salt: "SJXPlYpZ"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :yt_chop_dev, YtChopDev.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  yt_chop_dev: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  yt_chop_dev: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :cors_plug,
  origin: [
    "https://yt.chop.dev"
  ]

config :langchain,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  vertex_ai_key: System.get_env("VERTEX_AI_API_KEY"),
  vertex_ai: [
    project_id: System.get_env("VERTEX_AI_PROJECT_ID"),
    region: System.get_env("VERTEX_AI_REGION")
  ]

config :yt_chop_dev, :youtube_info_api, System.get_env("YOUTUBE_INFO_API")
config :yt_chop_dev, :tts_api_key, System.get_env("TTS_API_KEY")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
