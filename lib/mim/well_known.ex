defmodule Mim.WellKnown do
  @moduledoc """
  Builds Matrix `.well-known` discovery responses for this homeserver.
  """

  @doc """
  Returns the client discovery document for `GET /.well-known/matrix/client`.
  """
  @spec client_discovery() :: map()
  def client_discovery do
    %{"m.homeserver" => %{"base_url" => client_base_url()}}
    |> maybe_put_identity_server()
  end

  @doc """
  Returns the server discovery document for `GET /.well-known/matrix/server`.
  """
  @spec server_discovery() :: map()
  def server_discovery do
    %{"m.server" => federation_delegate()}
  end

  @doc """
  Returns the configured Matrix server name (domain).
  """
  @spec server_name() :: String.t()
  def server_name do
    matrix_config!(:server_name)
  end

  @doc """
  Returns the client-server API base URL for this homeserver.
  """
  @spec client_base_url() :: String.t()
  def client_base_url do
    case matrix_config(:client_base_url) do
      nil -> endpoint_base_url()
      url -> url
    end
  end

  @doc """
  Returns the federation delegate string (`host` or `host:port`).
  """
  @spec federation_delegate() :: String.t()
  def federation_delegate do
    server = matrix_config(:federation_server) || server_name()
    port = matrix_config!(:federation_port)
    "#{server}:#{port}"
  end

  defp maybe_put_identity_server(response) do
    case matrix_config(:identity_server_base_url) do
      nil -> response
      url -> Map.put(response, "m.identity_server", %{"base_url" => url})
    end
  end

  defp endpoint_base_url do
    endpoint_config = Application.get_env(:mim, MimWeb.Endpoint, [])
    url_config = Keyword.get(endpoint_config, :url, [])

    scheme = Keyword.get(url_config, :scheme, "http")
    host = Keyword.get(url_config, :host, "localhost")
    port = endpoint_http_port(endpoint_config, url_config)

    if default_port?(scheme, port) do
      "#{scheme}://#{host}"
    else
      "#{scheme}://#{host}:#{port}"
    end
  end

  defp endpoint_http_port(endpoint_config, url_config) do
    case Keyword.get(endpoint_config, :http) do
      http when is_list(http) -> Keyword.get(http, :port, Keyword.get(url_config, :port, 80))
      _ -> Keyword.get(url_config, :port, 80)
    end
  end

  defp default_port?("https", 443), do: true
  defp default_port?("http", 80), do: true
  defp default_port?(_, _), do: false

  defp matrix_config(key) do
    Application.get_env(:mim, :matrix, []) |> Keyword.get(key)
  end

  defp matrix_config!(key) do
    case matrix_config(key) do
      nil -> raise "Missing required :matrix config key #{inspect(key)}"
      value -> value
    end
  end
end
