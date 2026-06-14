defmodule Mim.LoginTest do
  use Mim.DataCase, async: true

  import Mim.AccountsFixtures

  alias Mim.Accounts
  alias Mim.Login
  alias Mim.Repo

  setup do
    stub_introspection(%{
      "active" => true,
      "sub" => "login-subject",
      "iss" => "https://idp.example.com",
      "username" => "alice"
    })

    :ok
  end

  test "flows/0 returns OIDC SSO and token login types" do
    assert %{
             "flows" => [
               %{
                 "type" => "m.login.sso",
                 "oauth_aware_preferred" => true,
                 "org.matrix.msc3824.delegated_oidc_compatibility" => true,
                 "identity_providers" => [
                   %{"id" => "oidc", "name" => "Continue with OIDC"}
                 ]
               },
               %{"type" => "m.login.token"}
             ]
           } = Login.flows()
  end

  test "login/1 creates an account and access token from an introspected OIDC token" do
    assert {:ok, response} =
             Login.login(%{
               "type" => "m.login.token",
               "token" => "oidc-access-token",
               "device_id" => "DEVICE1234"
             })

    assert %{
             "user_id" => "@alice:localhost",
             "access_token" => access_token,
             "device_id" => "DEVICE1234",
             "well_known" => %{
               "m.homeserver" => %{"base_url" => "http://localhost:4002"}
             }
           } = response

    assert is_binary(access_token) and access_token != ""
    assert {:ok, _} = Accounts.fetch_access_token(access_token)

    assert %Mim.Accounts.Account{oidc_sub: "login-subject"} =
             Repo.get_by(Mim.Accounts.Account, mxid: "@alice:localhost")
  end

  test "login/1 reuses an existing account for the same OIDC subject" do
    account_with_access_token(%{
      mxid: "@alice:localhost",
      oidc_sub: "login-subject",
      oidc_issuer: "https://idp.example.com"
    })

    assert {:ok, %{"user_id" => "@alice:localhost"}} =
             Login.login(%{"type" => "m.login.token", "token" => "oidc-access-token"})
  end

  test "login/1 returns forbidden for inactive tokens" do
    stub_introspection(%{"active" => false})

    assert {:error, {:forbidden, %{"errcode" => "M_FORBIDDEN"}}} =
             Login.login(%{"type" => "m.login.token", "token" => "bad-token"})
  end

  test "login/1 returns bad request for unknown login types" do
    assert {:error, {:bad_request, %{"errcode" => "M_UNKNOWN", "error" => error}}} =
             Login.login(%{"type" => "m.login.password", "password" => "secret"})

    assert error =~ "Unknown login type"
  end

  defp stub_introspection(body) do
    Req.Test.stub(Mim.Oidc.HTTP, fn conn ->
      Req.Test.json(conn, body)
    end)
  end
end
