defmodule Altar.Repo do
  use Ecto.Repo,
    otp_app: :altar,
    adapter: Ecto.Adapters.Postgres
end
