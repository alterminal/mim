defmodule MimWeb.LogoutController do
  use MimWeb, :controller

  alias Mim.Accounts

  def logout(conn, _params) do
    Accounts.revoke_access_token(conn.assigns.current_access_token)

    conn
    |> put_resp_content_type("application/json")
    |> json(%{})
  end

  def logout_all(conn, _params) do
    Accounts.revoke_all_access_tokens(conn.assigns.current_account)

    conn
    |> put_resp_content_type("application/json")
    |> json(%{})
  end

  def logout_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end

  def logout_all_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end
end
