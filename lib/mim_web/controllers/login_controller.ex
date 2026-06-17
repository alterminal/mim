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

  def sso_redirect(conn, params) do
    sso_redirect(conn, params, nil)
  end

  def sso_redirect_idp(conn, %{"idp_id" => idp_id} = params) do
    sso_redirect(conn, params, idp_id)
  end

  def sso_redirect_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end

  defp sso_redirect(conn, params, idp_id) do
    case Mim.Login.Sso.redirect_request(params, idp_id) do
      {:ok, %{location: location, session: session}} ->
        conn
        |> put_session(:sso, session)
        |> redirect(external: location)

      {:error, status, error} ->
        conn
        |> put_resp_content_type("application/json")
        |> put_status(status_code(status))
        |> json(error)
    end
  end

  defp status_code(:bad_request), do: :bad_request
  defp status_code(:not_found), do: :not_found
  defp status_code(:server_error), do: :internal_server_error

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
