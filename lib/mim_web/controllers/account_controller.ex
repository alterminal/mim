defmodule MimWeb.AccountController do
  use MimWeb, :controller

  alias Mim.Account

  def whoami(conn, _params) do
    conn
    |> put_resp_content_type("application/json")
    |> json(Account.whoami(conn.assigns.current_account))
  end

  def whoami_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end
end
