defmodule Mim.Repo.Migrations.CreateRoomMemberships do
  use Ecto.Migration

  def change do
    create table(:room_memberships, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :room_id, references(:rooms, type: :binary_id, on_delete: :delete_all), null: false

      add :account_id, references(:accounts, type: :binary_id, on_delete: :delete_all),
        null: false

      add :membership, :string, null: false
      add :invited_by_id, references(:accounts, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:room_memberships, [:room_id, :account_id])
    create index(:room_memberships, [:room_id])
    create index(:room_memberships, [:account_id])
  end
end
