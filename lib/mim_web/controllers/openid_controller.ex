defmodule MimWeb.OpenIdController do
  use MimWeb, :controller

  alias Mim.Matrix.Errors
  alias Mim.OpenId

  def request_token(conn, %{"user_id" => user_id}) do
    authenticated_mxid = conn.assigns.current_account.mxid

    conn =
      conn
      |> put_resp_content_type("application/json")

    case OpenId.request_token(authenticated_mxid, user_id) do
      {:ok, response} ->
        json(conn, response)

      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(Errors.forbidden())

      {:error, %{"errcode" => _} = error} ->
        conn
        |> put_status(:bad_request)
        |> json(error)

      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{"errcode" => "M_UNKNOWN", "error" => "Internal server error"})
    end
  end

  def request_token_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end
end
