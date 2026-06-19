defmodule MimWeb.Identity.HashDetailsControllerTest do
  use MimWeb.ConnCase, async: true

  import Mim.AccountsFixtures

  setup do
    %{account: _account, access_token: access_token} = account_with_access_token()
    %{access_token: access_token}
  end

  defp hash_details(conn, access_token) do
    conn
    |> put_req_header("authorization", "Bearer #{access_token}")
    |> get("/_matrix/identity/v2/hash_details")
  end

  test "GET /_matrix/identity/v2/hash_details returns algorithms and lookup pepper", %{
    conn: conn,
    access_token: access_token
  } do
    conn = hash_details(conn, access_token.token)

    assert %{
             "algorithms" => ["sha256", "none"],
             "lookup_pepper" => "test-pepper"
           } = json_response(conn, 200)

    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
  end

  test "GET accepts access_token query parameter", %{conn: conn, access_token: access_token} do
    conn =
      get(conn, "/_matrix/identity/v2/hash_details?access_token=#{access_token.token}")

    assert %{"algorithms" => ["sha256", "none"], "lookup_pepper" => "test-pepper"} =
             json_response(conn, 200)
  end

  test "returns 401 when access token is missing", %{conn: conn} do
    conn = get(conn, "/_matrix/identity/v2/hash_details")

    assert %{"errcode" => "M_UNAUTHORIZED"} = json_response(conn, 401)
  end

  test "returns 401 when access token is unknown", %{conn: conn} do
    conn = hash_details(conn, "unknown-token")

    assert %{"errcode" => "M_UNAUTHORIZED"} = json_response(conn, 401)
  end

  test "OPTIONS returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/_matrix/identity/v2/hash_details")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end
end
