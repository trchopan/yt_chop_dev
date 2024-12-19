defmodule YtChopDev.Repo do
  use Ecto.Repo,
    otp_app: :yt_chop_dev,
    adapter: Ecto.Adapters.Postgres
end
