defmodule Mim.OidcTest do
  use ExUnit.Case, async: true

  alias Mim.Oidc

  test "configured?/0 is true when issuer and client_id are set" do
    assert Oidc.configured?()
  end

  test "issuer/0 returns configured issuer" do
    assert Oidc.issuer() == "https://idp.example.com"
  end

  test "client_id/0 and client_secret/0 return configured credentials" do
    assert Oidc.client_id() == "mim-test"
    assert Oidc.client_secret() == "test-secret"
  end

  test "scopes/0 returns configured scopes" do
    assert Oidc.scopes() == ~w(openid profile email)
  end

  test "redirect_uri/0 returns configured redirect URI" do
    assert Oidc.redirect_uri() ==
             "http://localhost:4002/_matrix/client/v3/login/sso/callback"
  end

  test "discovery_document_url/0 derives URL from issuer" do
    assert Oidc.discovery_document_url() ==
             "https://idp.example.com/.well-known/openid-configuration"
  end

  test "identity_providers/0 returns configured providers" do
    assert [%{id: "oidc", name: "Continue with OIDC"}] = Oidc.identity_providers()
  end

  test "introspection_endpoint/0 returns configured endpoint" do
    assert Oidc.introspection_endpoint() == "https://idp.example.com/oauth2/introspect"
  end

  test "authorization_endpoint/0 returns configured endpoint" do
    assert Oidc.authorization_endpoint() == "https://idp.example.com/oauth2/authorize"
  end
end
