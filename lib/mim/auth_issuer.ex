defmodule Mim.AuthIssuer do
  @moduledoc """
  Builds the auth issuer response for `GET /_matrix/client/v3/auth_issuer`.
  """

  @cache_control "public, max-age=600, s-maxage=3600, stale-while-revalidate=600"
  @not_configured_error "OIDC discovery has not been configured on this homeserver"

  @doc """
  Returns the Cache-Control header value for auth issuer responses.
  """
  @spec cache_control() :: String.t()
  def cache_control, do: @cache_control

  @doc """
  Returns the auth issuer document when OIDC is configured.

  When OIDC is not configured, returns a Matrix `M_NOT_FOUND` error payload.
  """
  @spec document() :: {:ok, map()} | {:error, map()}
  def document do
    if Mim.Oidc.configured?() do
      {:ok, %{"issuer" => Mim.Oidc.issuer()}}
    else
      {:error, not_configured()}
    end
  end

  defp not_configured do
    %{"errcode" => "M_NOT_FOUND", "error" => @not_configured_error}
  end
end
