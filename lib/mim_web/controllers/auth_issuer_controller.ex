defmodule MimWeb.AuthIssuerController do
  use MimWeb, :controller

  def show(conn, _params) do
    conn =
      conn
      |> put_resp_header("cache-control", Mim.AuthIssuer.cache_control())
      |> put_resp_content_type("application/json")

    case Mim.AuthIssuer.document() do
      {:ok, document} ->
        json(conn, document)

      {:error, error} ->
        conn
        |> put_status(:not_found)
        |> json(error)
    end
  end

  def show_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end
end
