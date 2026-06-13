defmodule MimWeb.WellKnownControllerTest do
  use MimWeb.ConnCase, async: true

  test "GET /.well-known/matrix/client returns discovery document with CORS headers", %{
    conn: conn
  } do
    conn = get(conn, "/.well-known/matrix/client")

    assert %{
             "m.homeserver" => %{"base_url" => "http://localhost:4002"}
           } = json_response(conn, 200)

    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
  end

  test "OPTIONS /.well-known/matrix/client returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/.well-known/matrix/client")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end

  test "GET /.well-known/matrix/server returns federation delegate with cache headers", %{
    conn: conn
  } do
    conn = get(conn, "/.well-known/matrix/server")

    assert %{"m.server" => "localhost:8448"} = json_response(conn, 200)
    assert get_resp_header(conn, "cache-control") == ["public, max-age=86400"]
  end
end
