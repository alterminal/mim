defmodule Mim.Rooms.Room do
  @moduledoc """
  A Matrix room hosted on this homeserver.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @room_id_regex ~r/^![a-z0-9._=\/-]+:[a-z0-9][a-z0-9.\-]*$/i
  @default_room_version "10"

  schema "rooms" do
    field :room_id, :string
    field :name, :string
    field :topic, :string
    field :visibility, Ecto.Enum, values: [:public, :private], default: :private
    field :room_version, :string, default: @default_room_version

    belongs_to :creator, Mim.Accounts.Account
    has_many :memberships, Mim.Rooms.Membership

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(room, attrs) do
    room
    |> cast(attrs, [:room_id, :name, :topic, :visibility, :room_version, :creator_id])
    |> validate_required([:room_id, :creator_id])
    |> validate_format(:room_id, @room_id_regex,
      message: "must be a valid Matrix room ID (!room:server)"
    )
    |> unique_constraint(:room_id)
    |> foreign_key_constraint(:creator_id)
  end
end
