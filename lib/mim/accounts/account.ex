defmodule Mim.Accounts.Account do
  @moduledoc """
  A Matrix account linked to an OIDC identity.

  Authentication is handled externally via OIDC; there is no local password.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @mxid_regex ~r/^@[a-z0-9._=\/-]+:[a-z0-9][a-z0-9.\-]*$/i

  schema "accounts" do
    field :mxid, :string
    field :oidc_sub, :string
    field :oidc_issuer, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:mxid, :oidc_sub, :oidc_issuer])
    |> validate_required([:mxid, :oidc_sub, :oidc_issuer])
    |> validate_format(:mxid, @mxid_regex, message: "must be a valid Matrix ID (@user:server)")
    |> unique_constraint(:mxid)
    |> unique_constraint([:oidc_issuer, :oidc_sub])
  end
end
