defmodule MimWeb.RoomControllerTest do
  use MimWeb.ConnCase, async: true

  import Mim.AccountsFixtures

  @mxid "@alice:localhost"

  setup do
    %{account: account, access_token: access_token} =
      account_with_access_token(%{mxid: @mxid})

    %{account: account, access_token: access_token}
  end

  defp create_room(conn, access_token, body \\ %{}) do
    conn
    |> put_req_header("authorization", "Bearer #{access_token}")
    |> post("/_matrix/client/v3/createRoom", body)
  end

  test "POST /_matrix/client/v3/createRoom creates a room", %{
    conn: conn,
    access_token: access_token
  } do
    conn =
      create_room(conn, access_token.token, %{
        "name" => "General",
        "topic" => "Off-topic",
        "visibility" => "public"
      })

    assert %{"room_id" => room_id} = json_response(conn, 200)
    assert room_id =~ ~r/^![a-z0-9._=\/-]+:localhost$/i
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end

  test "POST /_matrix/client/v3/createRoom accepts access_token query parameter", %{
    conn: conn,
    access_token: access_token
  } do
    conn =
      post(conn, "/_matrix/client/v3/createRoom?access_token=#{access_token.token}", %{})

    assert %{"room_id" => _} = json_response(conn, 200)
  end

  test "POST /_matrix/client/v3/createRoom returns 400 for unsupported room version", %{
    conn: conn,
    access_token: access_token
  } do
    conn = create_room(conn, access_token.token, %{"room_version" => "11"})

    assert %{
             "errcode" => "M_UNSUPPORTED_ROOM_VERSION",
             "room_version" => "11"
           } = json_response(conn, 400)
  end

  test "returns 401 when access token is missing", %{conn: conn} do
    conn = post(conn, "/_matrix/client/v3/createRoom", %{})

    assert %{"errcode" => "M_MISSING_TOKEN"} = json_response(conn, 401)
  end

  test "returns 401 when access token is unknown", %{conn: conn} do
    conn = create_room(conn, "unknown-token")

    assert %{"errcode" => "M_UNKNOWN_TOKEN"} = json_response(conn, 401)
  end

  test "OPTIONS /_matrix/client/v3/createRoom returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/_matrix/client/v3/createRoom")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end
end
