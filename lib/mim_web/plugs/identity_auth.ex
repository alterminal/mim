defmodule MimWeb.Plugs.IdentityAuth do
  @moduledoc """
  Authenticates Matrix identity service requests using an access token.

  Tokens may be supplied via the `Authorization: Bearer` header or the
  deprecated `access_token` query parameter.
  """

  import Plug.Conn

  alias Mim.Accounts
  alias Mim.Identity.Errors

  def init(opts), do: opts

  def call(conn, _opts) do
    case fetch_access_token(conn) do
      nil ->
        unauthorized(conn)

      token ->
        case Accounts.fetch_access_token(token) do
          {:ok, access_token} ->
            conn
            |> assign(:current_account, access_token.account)
            |> assign(:current_access_token, access_token)

          {:error, :unknown_token} ->
            unauthorized(conn)
        end
    end
  end

  defp unauthorized(conn) do
    conn
    |> put_status(:unauthorized)
    |> put_resp_content_type("application/json")
    |> Phoenix.Controller.json(Errors.unauthorized())
    |> halt()
  end

  defp fetch_access_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] -> String.trim(token)
      _ -> conn.query_params["access_token"]
    end
    |> case do
      token when is_binary(token) and token != "" -> token
      _ -> nil
    end
  end
end
