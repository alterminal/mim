defmodule MimWeb.Identity.HashDetailsController do
  use MimWeb, :controller

  def show(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> json(Mim.Identity.HashDetails.document())
  end

  def show_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end
end
