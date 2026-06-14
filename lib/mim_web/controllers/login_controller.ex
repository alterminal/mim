defmodule MimWeb.LoginController do
  use MimWeb, :controller

  def index(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> json(Mim.Login.flows())
  end

  def index_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end

  def create(conn, params) do
    conn = put_resp_content_type(conn, "application/json")

    case Mim.Login.login(params) do
      {:ok, response} ->
        json(conn, response)

      {:error, {:bad_request, error}} ->
        conn
        |> put_status(:bad_request)
        |> json(error)

      {:error, {:forbidden, error}} ->
        conn
        |> put_status(:forbidden)
        |> json(error)

      {:error, {:server_error, error}} ->
        conn
        |> put_status(:internal_server_error)
        |> json(error)
    end
  end
end
