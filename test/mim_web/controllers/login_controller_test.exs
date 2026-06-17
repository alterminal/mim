defmodule MimWeb.LoginControllerTest do
  use MimWeb.ConnCase, async: true

  test "GET /_matrix/client/v3/login returns OIDC login flows with CORS headers", %{
    conn: conn
  } do
    conn = get(conn, "/_matrix/client/v3/login")

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
           } = json_response(conn, 200)

    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
  end

  test "OPTIONS /_matrix/client/v3/login returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/_matrix/client/v3/login")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end

  test "POST /_matrix/client/v3/login authenticates via OIDC token introspection", %{conn: conn} do
    Req.Test.stub(Mim.Oidc.HTTP, fn plug_conn ->
      Req.Test.json(plug_conn, %{
        "active" => true,
        "sub" => "controller-subject",
        "iss" => "https://idp.example.com",
        "username" => "bob"
      })
    end)

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/_matrix/client/v3/login", %{
        "type" => "m.login.token",
        "token" => "oidc-access-token",
        "device_id" => "MYDEVICE01"
      })

    assert %{
             "user_id" => "@bob:localhost",
             "access_token" => access_token,
             "device_id" => "MYDEVICE01",
             "well_known" => %{
               "m.homeserver" => %{"base_url" => "http://localhost:4002"}
             }
           } = json_response(conn, 200)

    assert is_binary(access_token) and access_token != ""
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end

  test "POST /_matrix/client/v3/login returns 403 for inactive tokens", %{conn: conn} do
    Req.Test.stub(Mim.Oidc.HTTP, fn plug_conn ->
      Req.Test.json(plug_conn, %{"active" => false})
    end)

    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/_matrix/client/v3/login", %{
        "type" => "m.login.token",
        "token" => "bad-token"
      })

    assert %{"errcode" => "M_FORBIDDEN"} = json_response(conn, 403)
  end

  test "GET /_matrix/client/v3/login/sso/redirect redirects to the OIDC provider", %{
    conn: conn
  } do
    Req.Test.stub(Mim.Oidc.HTTP, fn plug_conn ->
      Req.Test.json(plug_conn, %{
        "authorization_endpoint" => "https://idp.example.com/oauth2/authorize",
        "introspection_endpoint" => "https://idp.example.com/oauth2/introspect",
        "code_challenge_methods_supported" => ["S256"]
      })
    end)

    conn =
      get(
        conn,
        "/_matrix/client/v3/login/sso/redirect?redirectUrl=#{URI.encode("https://app.example.com/callback")}"
      )

    assert redirected_to(conn) =~ "https://idp.example.com/oauth2/authorize?"
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]

    assert %{
             state: state,
             nonce: nonce,
             redirect_url: "https://app.example.com/callback",
             code_verifier: code_verifier
           } = get_session(conn, :sso)

    assert is_binary(state) and state != ""
    assert is_binary(nonce) and nonce != ""
    assert code_verifier == nil
  end

  test "GET /_matrix/client/v3/login/sso/redirect/:idp_id selects the identity provider", %{
    conn: conn
  } do
    Req.Test.stub(Mim.Oidc.HTTP, fn plug_conn ->
      Req.Test.json(plug_conn, %{
        "authorization_endpoint" => "https://idp.example.com/oauth2/authorize",
        "introspection_endpoint" => "https://idp.example.com/oauth2/introspect"
      })
    end)

    conn =
      get(
        conn,
        "/_matrix/client/v3/login/sso/redirect/oidc?redirectUrl=#{URI.encode("https://app.example.com/callback")}"
      )

    assert redirected_to(conn) =~ "https://idp.example.com/oauth2/authorize?"
    assert get_session(conn, :sso).idp_id == "oidc"
  end

  test "GET /_matrix/client/v3/login/sso/redirect returns 400 when redirectUrl is missing", %{
    conn: conn
  } do
    conn = get(conn, "/_matrix/client/v3/login/sso/redirect")

    assert %{"errcode" => "M_INVALID_PARAM"} = json_response(conn, 400)
  end

  test "OPTIONS /_matrix/client/v3/login/sso/redirect returns CORS preflight response", %{
    conn: conn
  } do
    conn = options(conn, "/_matrix/client/v3/login/sso/redirect")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end
end
