defmodule Mim.WellKnown.Client do
  @moduledoc """
  Fetches Matrix `.well-known` discovery documents from remote servers.
  """

  @client_path "/.well-known/matrix/client"
  @server_path "/.well-known/matrix/server"

  @type discovery_error ::
          :not_found
          | :invalid_response
          | {:http_error, non_neg_integer()}
          | {:request_failed, term()}

  @doc """
  Discovers the client-server API base URL for a Matrix server name.

  Returns `{:ok, %{homeserver_base_url: url, identity_server_base_url: url | nil}}`
  or `{:error, reason}`.
  """
  @spec discover_client(String.t(), keyword()) ::
          {:ok, map()} | {:error, discovery_error()}
  def discover_client(server_name, opts \\ []) do
    with {:ok, body} <- fetch_json(server_name, @client_path, opts),
         {:ok, homeserver_base_url} <- parse_homeserver_base_url(body) do
      {:ok,
       %{
         homeserver_base_url: homeserver_base_url,
         identity_server_base_url: parse_identity_server_base_url(body)
       }}
    end
  end

  @doc """
  Discovers the federation delegate for a Matrix server name.

  Returns `{:ok, %{server: host, port: port | nil}}` or `{:error, reason}`.
  """
  @spec discover_server(String.t(), keyword()) ::
          {:ok, map()} | {:error, discovery_error()}
  def discover_server(server_name, opts \\ []) do
    with {:ok, body} <- fetch_json(server_name, @server_path, opts),
         {:ok, delegate} <- parse_server_delegate(body) do
      {:ok, delegate}
    end
  end

  defp fetch_json(server_name, path, opts) do
    req_opts = req_options(Keyword.get(opts, :req_options, []))

    case Mim.WellKnown.HTTP.get(well_known_url(server_name, path), req_opts) do
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: 404}} ->
        {:error, :not_found}

      {:ok, %{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  defp req_options(extra_opts) do
    [
      headers: [{"accept", "application/json"}],
      redirect: :follow,
      max_redirects: 5,
      decode_body: true
    ]
    |> Keyword.merge(Application.get_env(:mim, :well_known_req_options, []))
    |> Keyword.merge(extra_opts)
  end

  defp well_known_url(server_name, path) do
    "https://#{server_name}#{path}"
  end

  defp parse_homeserver_base_url(%{"m.homeserver" => %{"base_url" => base_url}})
       when is_binary(base_url) and base_url != "" do
    {:ok, base_url}
  end

  defp parse_homeserver_base_url(_), do: {:error, :invalid_response}

  defp parse_identity_server_base_url(%{"m.identity_server" => %{"base_url" => base_url}})
       when is_binary(base_url) and base_url != "" do
    base_url
  end

  defp parse_identity_server_base_url(_), do: nil

  defp parse_server_delegate(%{"m.server" => delegate})
       when is_binary(delegate) and delegate != "" do
    case String.split(delegate, ":", parts: 2) do
      [host] ->
        {:ok, %{server: host, port: nil}}

      [host, port] ->
        case Integer.parse(port) do
          {port_int, ""} -> {:ok, %{server: host, port: port_int}}
          _ -> {:error, :invalid_response}
        end
    end
  end

  defp parse_server_delegate(_), do: {:error, :invalid_response}
end
