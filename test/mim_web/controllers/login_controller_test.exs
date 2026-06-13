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
end
