defmodule Mim.Repo.Migrations.CreateRooms do
  use Ecto.Migration

  def change do
    create table(:rooms, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :room_id, :string, null: false
      add :name, :string
      add :topic, :string
      add :visibility, :string, null: false, default: "private"
      add :room_version, :string, null: false, default: "10"
      add :creator_id, references(:accounts, type: :binary_id, on_delete: :nothing), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:rooms, [:room_id])
    create index(:rooms, [:creator_id])
  end
end
