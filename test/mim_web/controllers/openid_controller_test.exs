defmodule MimWeb.OpenIdControllerTest do
  use MimWeb.ConnCase, async: true

  import Mim.AccountsFixtures

  @mxid "@alice:localhost"

  setup do
    %{account: account, access_token: access_token} =
      account_with_access_token(%{mxid: @mxid})

    %{account: account, access_token: access_token}
  end

  defp request_token(conn, user_id, access_token) do
    conn
    |> put_req_header("authorization", "Bearer #{access_token}")
    |> put_req_header("content-type", "application/json")
    |> post("/_matrix/client/v1/user/#{URI.encode(user_id)}/openid/request_token", %{})
  end

  test "POST /_matrix/client/v1/user/{userId}/openid/request_token returns an OpenID token",
       %{conn: conn, access_token: access_token} do
    conn = request_token(conn, @mxid, access_token.token)

    assert %{
             "access_token" => token,
             "token_type" => "Bearer",
             "matrix_server_name" => "localhost",
             "expires_in" => 3600
           } = json_response(conn, 200)

    assert is_binary(token) and token != ""
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end

  test "POST /_matrix/client/v3/user/{userId}/openid/request_token is also supported", %{
    conn: conn,
    access_token: access_token
  } do
    conn =
      conn
      |> put_req_header("authorization", "Bearer #{access_token.token}")
      |> put_req_header("content-type", "application/json")
      |> post("/_matrix/client/v3/user/#{URI.encode(@mxid)}/openid/request_token", %{})

    assert %{"access_token" => _} = json_response(conn, 200)
  end

  test "returns 401 when access token is missing", %{conn: conn} do
    conn =
      conn
      |> put_req_header("content-type", "application/json")
      |> post("/_matrix/client/v1/user/#{URI.encode(@mxid)}/openid/request_token", %{})

    assert %{"errcode" => "M_MISSING_TOKEN"} = json_response(conn, 401)
  end

  test "returns 401 when access token is unknown", %{conn: conn} do
    conn = request_token(conn, @mxid, "unknown-token")

    assert %{"errcode" => "M_UNKNOWN_TOKEN"} = json_response(conn, 401)
  end

  test "returns 403 when user ID does not match the authenticated user", %{
    conn: conn,
    access_token: access_token
  } do
    conn = request_token(conn, "@bob:localhost", access_token.token)

    assert %{"errcode" => "M_FORBIDDEN"} = json_response(conn, 403)
  end

  test "OPTIONS returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/_matrix/client/v1/user/#{URI.encode(@mxid)}/openid/request_token")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end
end
