defmodule Mim.AccountTest do
  use Mim.DataCase, async: true

  alias Mim.Account
  alias Mim.Accounts

  test "whoami/1 returns the account MXID" do
    {:ok, account} =
      Accounts.create_account(%{
        mxid: "@alice:localhost",
        oidc_sub: "sub-1",
        oidc_issuer: "https://idp.example.com"
      })

    assert Account.whoami(account) == %{"user_id" => "@alice:localhost"}
  end
end
