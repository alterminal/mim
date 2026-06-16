defmodule MimWeb.RoomControllerTest do
  use MimWeb.ConnCase, async: true

  import Mim.AccountsFixtures

  @mxid "@alice:localhost"

  setup do
    %{account: account, access_token: access_token} =
      account_with_access_token(%{mxid: @mxid})

    %{account: account, access_token: access_token}
  end

  defp auth_conn(conn, access_token) do
    put_req_header(conn, "authorization", "Bearer #{access_token}")
  end

  defp create_room(conn, access_token, body \\ %{}) do
    conn
    |> auth_conn(access_token)
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

  test "invite and join flow for a private room", %{conn: conn, access_token: access_token} do
    %{account: invitee, access_token: invitee_token} =
      account_with_access_token(%{mxid: "@bob:localhost"})

    conn = create_room(conn, access_token.token, %{"visibility" => "private"})
    assert %{"room_id" => room_id} = json_response(conn, 200)

    encoded_room_id = URI.encode(room_id)

    conn =
      build_conn()
      |> auth_conn(access_token.token)
      |> post("/_matrix/client/v3/rooms/#{encoded_room_id}/invite", %{
        "user_id" => invitee.mxid
      })

    assert json_response(conn, 200) == %{}

    conn =
      build_conn()
      |> auth_conn(invitee_token.token)
      |> post("/_matrix/client/v3/join/#{encoded_room_id}", %{})

    assert %{"room_id" => ^room_id} = json_response(conn, 200)
  end

  test "POST invite returns 403 when inviter is not a room member", %{
    conn: conn,
    access_token: access_token
  } do
    %{access_token: outsider_token} = account_with_access_token(%{mxid: "@outsider:localhost"})
    %{account: invitee} = account_with_access_token(%{mxid: "@target:localhost"})

    conn = create_room(conn, access_token.token, %{})
    assert %{"room_id" => room_id} = json_response(conn, 200)

    conn =
      build_conn()
      |> auth_conn(outsider_token.token)
      |> post("/_matrix/client/v3/rooms/#{URI.encode(room_id)}/invite", %{
        "user_id" => invitee.mxid
      })

    assert %{"errcode" => "M_FORBIDDEN"} = json_response(conn, 403)
  end

  test "POST invite returns 404 for unknown room", %{conn: conn, access_token: access_token} do
    conn =
      conn
      |> auth_conn(access_token.token)
      |> post("/_matrix/client/v3/rooms/#{URI.encode("!missing:localhost")}/invite", %{
        "user_id" => @mxid
      })

    assert %{"errcode" => "M_NOT_FOUND"} = json_response(conn, 404)
  end

  test "POST join returns 403 for private room without invite", %{
    conn: conn,
    access_token: access_token
  } do
    %{access_token: outsider_token} = account_with_access_token(%{mxid: "@guest:localhost"})

    conn = create_room(conn, access_token.token, %{"visibility" => "private"})
    assert %{"room_id" => room_id} = json_response(conn, 200)

    conn =
      build_conn()
      |> auth_conn(outsider_token.token)
      |> post("/_matrix/client/v3/join/#{URI.encode(room_id)}", %{})

    assert %{"errcode" => "M_FORBIDDEN"} = json_response(conn, 403)
  end

  test "OPTIONS /_matrix/client/v3/rooms/:roomId/invite returns CORS preflight", %{conn: conn} do
    conn = options(conn, "/_matrix/client/v3/rooms/#{URI.encode("!room:localhost")}/invite")

    assert response(conn, 204) == ""
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end

  test "OPTIONS /_matrix/client/v3/join/:roomId returns CORS preflight", %{conn: conn} do
    conn = options(conn, "/_matrix/client/v3/join/#{URI.encode("!room:localhost")}")

    assert response(conn, 204) == ""
    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
  end
end
