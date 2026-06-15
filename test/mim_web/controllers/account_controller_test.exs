defmodule MimWeb.AccountControllerTest do
  use MimWeb.ConnCase, async: true

  import Mim.AccountsFixtures

  @mxid "@alice:localhost"

  setup do
    %{account: account, access_token: access_token} =
      account_with_access_token(%{mxid: @mxid})

    %{account: account, access_token: access_token}
  end

  defp whoami(conn, access_token) do
    conn
    |> put_req_header("authorization", "Bearer #{access_token}")
    |> get("/_matrix/client/v3/account/whoami")
  end

  test "GET /_matrix/client/v3/account/whoami returns the authenticated user", %{
    conn: conn,
    access_token: access_token
  } do
    conn = whoami(conn, access_token.token)

    assert %{"user_id" => @mxid} = json_response(conn, 200)
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end

  test "GET /_matrix/client/v3/account/whoami accepts access_token query parameter", %{
    conn: conn,
    access_token: access_token
  } do
    conn = get(conn, "/_matrix/client/v3/account/whoami?access_token=#{access_token.token}")

    assert %{"user_id" => @mxid} = json_response(conn, 200)
  end

  test "returns 401 when access token is missing", %{conn: conn} do
    conn = get(conn, "/_matrix/client/v3/account/whoami")

    assert %{"errcode" => "M_MISSING_TOKEN"} = json_response(conn, 401)
  end

  test "returns 401 when access token is unknown", %{conn: conn} do
    conn = whoami(conn, "unknown-token")

    assert %{"errcode" => "M_UNKNOWN_TOKEN"} = json_response(conn, 401)
  end

  test "OPTIONS returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/_matrix/client/v3/account/whoami")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end
end
