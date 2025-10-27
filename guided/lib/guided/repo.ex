defmodule Guided.Repo do
  use Ecto.Repo,
    otp_app: :guided,
    adapter: Ecto.Adapters.Postgres
end
