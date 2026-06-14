defmodule Mim.Oidc.Introspection do
  @moduledoc """
  Validates OAuth 2.0 access tokens using the OIDC introspection endpoint (RFC 7662).
  """

  alias Mim.Oidc
  alias Mim.Oidc.Discovery
  alias Mim.Oidc.HTTP

  @doc """
  Introspects an access token and returns active token claims.

  Returns `{:error, :inactive}` when the provider marks the token inactive.
  """
  @spec introspect(String.t()) ::
          {:ok, map()}
          | {:error,
             :inactive
             | :not_configured
             | :no_endpoint
             | :request_failed
             | :invalid_response}
  def introspect(token) when is_binary(token) do
    with :ok <- ensure_configured(),
         {:ok, endpoint} <- Discovery.introspection_endpoint(),
         {:ok, body} <- post_introspection(endpoint, token),
         {:ok, claims} <- parse_active_claims(body) do
      {:ok, claims}
    end
  end

  defp ensure_configured do
    if Oidc.configured?(), do: :ok, else: {:error, :not_configured}
  end

  defp post_introspection(endpoint, token) do
    IO.inspect(Oidc.client_id())
    opts =
      req_options()
      |> Keyword.update(:headers, [], fn headers ->
        [{"content-type", "application/x-www-form-urlencoded"} | headers]
      end)
      |> Keyword.put(
        :body,
        URI.encode_query(client_id: Oidc.client_id(), token: token)
      )
    case HTTP.post(endpoint, opts) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: _status}} ->
        {:error, :request_failed}

      {:error, _reason} ->
        {:error, :request_failed}
    end
  end

  defp parse_active_claims(%{"active" => true} = claims) do
    case Map.get(claims, "sub") do
      sub when is_binary(sub) and sub != "" ->
        issuer = Map.get(claims, "iss") || Oidc.issuer()
        {:ok, Map.put(claims, "iss", issuer)}

      _ ->
        {:error, :invalid_response}
    end
  end

  defp parse_active_claims(%{"active" => false}), do: {:error, :inactive}
  defp parse_active_claims(_), do: {:error, :invalid_response}

  defp req_options do
    [
      headers: [{"accept", "application/json"}],
      decode_body: true
    ]
    |> Keyword.merge(Application.get_env(:mim, :oidc_req_options, []))
  end
end
