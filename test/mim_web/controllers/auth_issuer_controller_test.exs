defmodule MimWeb.AuthIssuerControllerTest do
  use MimWeb.ConnCase, async: false

  setup do
    original = Application.get_env(:mim, :oidc, [])

    on_exit(fn -> Application.put_env(:mim, :oidc, original) end)

    :ok
  end

  test "GET /_matrix/client/v3/auth_issuer returns issuer with CORS and cache headers", %{
    conn: conn
  } do
    conn = get(conn, "/_matrix/client/v3/auth_issuer")

    assert %{"issuer" => "https://idp.example.com"} = json_response(conn, 200)

    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]

    assert get_resp_header(conn, "cache-control") == [
             "public, max-age=600, s-maxage=3600, stale-while-revalidate=600"
           ]
  end

  test "GET /_matrix/client/v3/auth_issuer returns 404 when OIDC is not configured", %{
    conn: conn
  } do
    original = Application.get_env(:mim, :oidc, [])
    Application.put_env(:mim, :oidc, Keyword.merge(original, issuer: nil, client_id: nil))

    conn = get(conn, "/_matrix/client/v3/auth_issuer")

    assert %{"errcode" => "M_NOT_FOUND", "error" => error} = json_response(conn, 404)
    assert error =~ "OIDC discovery has not been configured"
  end

  test "OPTIONS /_matrix/client/v3/auth_issuer returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/_matrix/client/v3/auth_issuer")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end
end
