defmodule Mim.Repo.Migrations.CreateOpenidTokens do
  use Ecto.Migration

  def change do
    create table(:openid_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string, null: false
      add :mxid, :string, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:openid_tokens, [:token])
    create index(:openid_tokens, [:mxid])
    create index(:openid_tokens, [:expires_at])
  end
end
