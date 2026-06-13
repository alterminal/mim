defmodule MimWeb.WellKnownController do
  use MimWeb, :controller

  @server_cache_control "public, max-age=86400"

  def client(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> json(Mim.WellKnown.client_discovery())
  end

  def client_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end

  def server(conn, _params) do
    conn
    |> put_resp_header("cache-control", @server_cache_control)
    |> put_resp_content_type("application/json")
    |> json(Mim.WellKnown.server_discovery())
  end
end
