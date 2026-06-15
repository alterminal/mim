defmodule MimWeb.VersionsControllerTest do
  use MimWeb.ConnCase, async: true

  test "GET /_matrix/client/versions returns supported versions with CORS headers", %{
    conn: conn
  } do
    conn = get(conn, "/_matrix/client/versions")

    assert %{
             "versions" => [
               "r0.0.1",
               "r0.1.0",
               "r0.2.0",
               "r0.3.0",
               "r0.4.0",
               "r0.5.0",
               "r0.6.0",
               "r0.6.1",
               "v1.1",
               "v1.2",
               "v1.3",
               "v1.4",
               "v1.5",
               "v1.6",
               "v1.7",
               "v1.8",
               "v1.9",
               "v1.10",
               "v1.11"
             ],
             "unstable_features" => %{
               "org.matrix.msc2965.authentication" => true,
               "org.matrix.msc3824.delegated_oidc_compatibility" => true
             }
           } = json_response(conn, 200)

    assert get_resp_header(conn, "access-control-allow-origin") == ["*"]
    assert get_resp_header(conn, "content-type") == ["application/json; charset=utf-8"]
  end

  test "OPTIONS /_matrix/client/versions returns CORS preflight response", %{conn: conn} do
    conn = options(conn, "/_matrix/client/versions")

    assert response(conn, 204) == ""

    assert get_resp_header(conn, "access-control-allow-methods") == [
             "GET, POST, PUT, DELETE, OPTIONS"
           ]
  end
end
