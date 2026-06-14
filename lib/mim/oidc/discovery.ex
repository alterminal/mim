defmodule Mim.Oidc.Discovery do
  @moduledoc """
  Fetches OIDC provider metadata used for token introspection.
  """

  alias Mim.Oidc
  alias Mim.Oidc.HTTP

  @doc """
  Returns the OIDC provider metadata document.

  When `:introspection_endpoint` is configured directly, returns a minimal
  document containing only that endpoint.
  """
  @spec metadata() ::
          {:ok, map()}
          | {:error, :not_configured | :no_endpoint | :request_failed | :invalid_response}
  def metadata do
    cond do
      not Oidc.configured?() ->
        {:error, :not_configured}

      is_binary(Oidc.introspection_endpoint()) ->
        {:ok, %{"introspection_endpoint" => Oidc.introspection_endpoint()}}

      true ->
        fetch_metadata()
    end
  end

  @doc """
  Returns the configured or discovered token introspection endpoint URL.
  """
  @spec introspection_endpoint() ::
          {:ok, String.t()}
          | {:error, :not_configured | :no_endpoint | :request_failed | :invalid_response}
  def introspection_endpoint do
    case metadata() do
      {:ok, %{"introspection_endpoint" => endpoint}}
      when is_binary(endpoint) and endpoint != "" ->
        {:ok, endpoint}

      {:ok, _} ->
        {:error, :no_endpoint}

      {:error, _} = error ->
        error
    end
  end

  defp fetch_metadata do
    case Oidc.discovery_document_url() do
      nil ->
        {:error, :no_endpoint}

      url ->
        url
        |> HTTP.get(req_options())
        |> case do
          {:ok, %{status: 200, body: body}} when is_map(body) ->
            {:ok, body}

          {:ok, %{status: _status}} ->
            {:error, :request_failed}

          {:error, _reason} ->
            {:error, :request_failed}
        end
    end
  end

  defp req_options do
    [
      headers: [{"accept", "application/json"}],
      redirect: :follow,
      max_redirects: 5,
      decode_body: true
    ]
    |> Keyword.merge(Application.get_env(:mim, :oidc_req_options, []))
  end
end
