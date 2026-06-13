defmodule Mim.LoginTest do
  use ExUnit.Case, async: true

  alias Mim.Login

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
end
