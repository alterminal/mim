defmodule Mim.Repo do
  use Ecto.Repo,
    otp_app: :mim,
    adapter: Ecto.Adapters.Postgres
end
