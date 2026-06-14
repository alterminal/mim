defmodule Mim.Accounts.AccessToken do
  @moduledoc """
  A Matrix client access token issued to an authenticated account.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "access_tokens" do
    field :token, :string
    field :expires_at, :utc_datetime

    belongs_to :account, Mim.Accounts.Account

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(access_token, attrs) do
    access_token
    |> cast(attrs, [:token, :account_id, :expires_at])
    |> validate_required([:token, :account_id])
    |> unique_constraint(:token)
    |> foreign_key_constraint(:account_id)
  end
end
