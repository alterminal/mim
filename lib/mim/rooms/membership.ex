defmodule Mim.Rooms.Membership do
  @moduledoc """
  A Matrix room membership record for an account.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "room_memberships" do
    field :membership, Ecto.Enum, values: [:invite, :join, :leave, :ban]

    belongs_to :room, Mim.Rooms.Room
    belongs_to :account, Mim.Accounts.Account
    belongs_to :invited_by, Mim.Accounts.Account

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:room_id, :account_id, :membership, :invited_by_id])
    |> validate_required([:room_id, :account_id, :membership])
    |> foreign_key_constraint(:room_id)
    |> foreign_key_constraint(:account_id)
    |> foreign_key_constraint(:invited_by_id)
    |> unique_constraint([:room_id, :account_id])
  end
end
