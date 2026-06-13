defmodule MimWeb.Plugs.MatrixCors do
  @moduledoc """
  Adds Matrix-spec CORS headers for `.well-known` discovery endpoints.
  """

  import Plug.Conn

  @cors_headers %{
    "access-control-allow-origin" => "*",
    "access-control-allow-methods" => "GET, POST, PUT, DELETE, OPTIONS",
    "access-control-allow-headers" => "X-Requested-With, Content-Type, Authorization"
  }

  def init(opts), do: opts

  def call(conn, _opts) do
    Enum.reduce(@cors_headers, conn, fn {key, value}, conn ->
      put_resp_header(conn, key, value)
    end)
  end
end
