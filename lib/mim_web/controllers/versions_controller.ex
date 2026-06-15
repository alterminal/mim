defmodule MimWeb.VersionsController do
  use MimWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> json(Mim.Versions.document())
  end

  def index_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end
end
