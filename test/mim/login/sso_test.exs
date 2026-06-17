defmodule Mim.Login.SsoTest do
  use ExUnit.Case, async: true

  alias Mim.Login.Sso

  setup do
    Req.Test.stub(Mim.Oidc.HTTP, fn conn ->
      Req.Test.json(conn, %{
        "authorization_endpoint" => "https://idp.example.com/oauth2/authorize",
        "introspection_endpoint" => "https://idp.example.com/oauth2/introspect",
        "code_challenge_methods_supported" => ["S256"]
      })
    end)

    :ok
  end

  test "redirect_request/2 returns an authorization URL and session data" do
    assert {:ok, %{location: location, session: session}} =
             Sso.redirect_request(%{"redirectUrl" => "https://app.example.com/callback"})

    assert %URI{host: "idp.example.com", path: "/oauth2/authorize", query: query} =
             URI.parse(location)

    params = URI.decode_query(query)

    assert params["client_id"] == "mim-test"
    assert params["response_type"] == "code"
    assert params["redirect_uri"] == "http://localhost:4002/_matrix/client/v3/login/sso/callback"
    assert params["scope"] == "openid profile email"
    assert params["state"] == session.state
    assert params["nonce"] == session.nonce
    refute Map.has_key?(params, "code_challenge")

    assert session.redirect_url == "https://app.example.com/callback"
    assert session.idp_id == "oidc"
    assert session.code_verifier == nil
  end

  test "redirect_request/2 accepts custom URI schemes" do
    assert {:ok, %{session: session}} =
             Sso.redirect_request(%{"redirectUrl" => "element://vector/callback"})

    assert session.redirect_url == "element://vector/callback"
  end

  test "redirect_request/2 returns bad request when redirectUrl is missing" do
    assert {:error, :bad_request, %{"errcode" => "M_INVALID_PARAM", "error" => error}} =
             Sso.redirect_request(%{})

    assert error =~ "redirectUrl"
  end

  test "redirect_request/2 returns bad request for invalid redirectUrl" do
    assert {:error, :bad_request, %{"errcode" => "M_INVALID_PARAM"}} =
             Sso.redirect_request(%{"redirectUrl" => "not-a-url"})
  end

  test "redirect_request/2 returns not found for unknown identity providers" do
    assert {:error, :not_found, %{"errcode" => "M_NOT_FOUND"}} =
             Sso.redirect_request(
               %{"redirectUrl" => "https://app.example.com/callback"},
               "unknown"
             )
  end
end
