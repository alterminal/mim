defmodule Mim.AccountsFixtures do
  @moduledoc """
  Test helpers for creating accounts and access tokens.
  """

  alias Mim.Accounts

  @doc """
  Creates an account and access token for Matrix API tests.
  """
  def account_with_access_token(attrs \\ %{}) do
    account_attrs =
      Enum.into(attrs, %{
        mxid: unique_mxid(),
        oidc_sub: unique_oidc_sub(),
        oidc_issuer: "https://idp.example.com"
      })

    {:ok, account} = Accounts.create_account(account_attrs)
    {:ok, access_token} = Accounts.issue_access_token(account)

    %{account: account, access_token: access_token}
  end

  defp unique_mxid do
    "@#{System.unique_integer([:positive])}:localhost"
  end

  defp unique_oidc_sub do
    "sub-#{System.unique_integer([:positive])}"
  end
end
