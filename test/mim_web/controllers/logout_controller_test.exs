defmodule MimWeb.LogoutControllerTest do
  use MimWeb.ConnCase, async: true

  import Mim.AccountsFixtures

  alias Mim.Accounts

  @mxid "@alice:localhost"

  setup do
    %{account: account, access_token: access_token} =
      account_with_access_token(%{mxid: @mxid})

    %{account: account, access_token: access_token}
  end

  defp logout(conn, access_token) do
    conn
    |> put_req_header("authorization", "Bearer #{access_token}")
    |> post("/_matrix/client/v3/logout")
  end

  test "POST /_matrix/client/v3/logout revokes the current access token", %{
    conn: conn,
    access_token: access_token
  } do
    conn = logout(conn, access_token.token)

    assert %{} = json_response(conn, 200)
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    assert {:error, :unknown_token} = Accounts.fetch_access_token(access_token.token)
  end

  test "POST /_matrix/client/v3/logout accepts access_token query parameter", %{
    conn: conn,
    access_token: access_token
  } do
    conn = post(conn, "/_matrix/client/v3/logout?access_token=#{access_token.token}")

    assert %{} = json_response(conn, 200)
    assert {:error, :unknown_token} = Accounts.fetch_access_token(access_token.token)
  end

  test "POST /_matrix/client/v3/logout/all revokes all access tokens for the account", %{
    conn: conn,
    account: account,
    access_token: access_token
  } do
    {:ok, other_token} = Accounts.issue_access_token(account)

    conn =
      conn
      |> put_req_header("authorization", "Bearer #{access_token.token}")
      |> post("/_matrix/client/v3/logout/all")

    assert %{} = json_response(conn, 200)
    assert {:error, :unknown_token} = Accounts.fetch_access_token(access_token.token)
    assert {:error, :unknown_token} = Accounts.fetch_access_token(other_token.token)
  end

  test "returns 401 when access token is missing", %{conn: conn} do
    conn = post(conn, "/_matrix/client/v3/logout")

    assert %{"errcode" => "M_MISSING_TOKEN"} = json_response(conn, 401)
  end

  test "returns 401 when access token is unknown", %{conn: conn} do
    conn = logout(conn, "unknown-token")

    assert %{"errcode" => "M_UNKNOWN_TOKEN"} = json_response(conn, 401)
  end

  test "OPTIONS /_matrix/client/v3/logout returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/_matrix/client/v3/logout")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end

  test "OPTIONS /_matrix/client/v3/logout/all returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/_matrix/client/v3/logout/all")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end
end
