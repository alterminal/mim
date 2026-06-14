defmodule Mim.Repo.Migrations.CreateAccessTokens do
  use Ecto.Migration

  def change do
    create table(:access_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :token, :string, null: false

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :expires_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:access_tokens, [:token])
    create index(:access_tokens, [:account_id])
  end
end
