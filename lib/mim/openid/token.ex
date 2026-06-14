defmodule Mim.OpenId.Token do
  @moduledoc """
  A short-lived Matrix OpenID token for third-party identity verification.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "openid_tokens" do
    field :token, :string
    field :mxid, :string
    field :expires_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(openid_token, attrs) do
    openid_token
    |> cast(attrs, [:token, :mxid, :expires_at])
    |> validate_required([:token, :mxid, :expires_at])
    |> unique_constraint(:token)
  end
end
