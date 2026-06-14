defmodule Mim.Accounts do
  @moduledoc """
  Account and access token management for Matrix clients.
  """

  import Ecto.Query, warn: false

  alias Mim.Accounts.AccessToken
  alias Mim.Accounts.Account
  alias Mim.Repo

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

  defp generate_token do
    32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end
end
