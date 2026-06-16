defmodule Mim.Accounts do
  @moduledoc """
  Account and access token management for Matrix clients.
  """

  import Ecto.Query, warn: false

  alias Mim.Accounts.AccessToken
  alias Mim.Accounts.Account
  alias Mim.Repo
  alias Mim.WellKnown

  @localpart_regex ~r/^[a-z0-9._=\/-]+$/

  @doc """
  Creates an account with the given attributes.
  """
  @spec create_account(map()) :: {:ok, Account.t()} | {:error, Ecto.Changeset.t()}
  def create_account(attrs) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Issues a new access token for the given account.
  """
  @spec issue_access_token(Account.t(), keyword()) ::
          {:ok, AccessToken.t()} | {:error, Ecto.Changeset.t()}
  def issue_access_token(%Account{} = account, opts \\ []) do
    expires_at = Keyword.get(opts, :expires_at)

    %AccessToken{}
    |> AccessToken.changeset(%{
      token: generate_token(),
      account_id: account.id,
      expires_at: expires_at
    })
    |> Repo.insert()
  end

  @doc """
  Looks up a valid access token and preloads its account.
  """
  @spec fetch_access_token(String.t()) :: {:ok, AccessToken.t()} | {:error, :unknown_token}
  def fetch_access_token(token) when is_binary(token) do
    now = DateTime.utc_now(:second)

    AccessToken
    |> where([t], t.token == ^token)
    |> where([t], is_nil(t.expires_at) or t.expires_at > ^now)
    |> preload(:account)
    |> Repo.one()
    |> case do
      %AccessToken{} = access_token -> {:ok, access_token}
      nil -> {:error, :unknown_token}
    end
  end

  @doc """
  Revokes a single access token.
  """
  @spec revoke_access_token(AccessToken.t()) :: :ok
  def revoke_access_token(%AccessToken{} = access_token) do
    Repo.delete!(access_token)
    :ok
  end

  @doc """
  Revokes all access tokens for the given account.
  """
  @spec revoke_all_access_tokens(Account.t()) :: :ok
  def revoke_all_access_tokens(%Account{} = account) do
    AccessToken
    |> where([t], t.account_id == ^account.id)
    |> Repo.delete_all()

    :ok
  end

  @doc """
  Looks up an account by Matrix ID.
  """
  @spec fetch_account_by_mxid(String.t()) :: {:ok, Account.t()} | {:error, :not_found}
  def fetch_account_by_mxid(mxid) when is_binary(mxid) do
    case Repo.get_by(Account, mxid: mxid) do
      %Account{} = account -> {:ok, account}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Finds or creates an account from OIDC introspection claims.
  """
  @spec fetch_or_create_account_for_oidc(map()) ::
          {:ok, Account.t()} | {:error, Ecto.Changeset.t() | :invalid_localpart}
  def fetch_or_create_account_for_oidc(%{"sub" => oidc_sub, "iss" => oidc_issuer} = claims) do
    case Repo.get_by(Account, oidc_sub: oidc_sub, oidc_issuer: oidc_issuer) do
      %Account{} = account ->
        {:ok, account}

      nil ->
        with {:ok, localpart} <- localpart_from_claims(claims),
             {:ok, account} <-
               create_account(%{
                 mxid: mxid_for_localpart(localpart),
                 oidc_sub: oidc_sub,
                 oidc_issuer: oidc_issuer
               }) do
          {:ok, account}
        end
    end
  end

  defp localpart_from_claims(%{"sub" => _} = claims) do
    localpart =
      claims
      |> Map.get("username")
      |> case do
        username when is_binary(username) and username != "" ->
          sanitize_localpart(username)

        _ ->
          sanitize_localpart(Map.fetch!(claims, "sub"))
      end

    if Regex.match?(@localpart_regex, localpart) do
      {:ok, localpart}
    else
      {:error, :invalid_localpart}
    end
  end

  defp sanitize_localpart(value) do
    value
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9._=\/-]/, "_")
    |> String.trim("_")
    |> case do
      "" -> "user"
      localpart -> String.slice(localpart, 0, 255)
    end
  end

  defp mxid_for_localpart(localpart) do
    "@#{localpart}:#{WellKnown.server_name()}"
  end

  defp generate_token do
    32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end
end
