defmodule Mim.Oidc do
  @moduledoc """
  OIDC provider settings for Matrix SSO login.

  Configuration is read from `:mim, :oidc`. Required keys for a working SSO flow:

    * `:issuer` — OIDC provider issuer URL
    * `:client_id` — OAuth 2.0 client identifier
    * `:client_secret` — OAuth 2.0 client secret (set via environment in production)

  Optional keys:

    * `:scopes` — requested scopes (defaults to `["openid", "profile", "email"]`)
    * `:redirect_uri` — full redirect URI override
    * `:redirect_path` — path appended to the homeserver base URL when `:redirect_uri` is unset
    * `:discovery_url` — OpenID Provider Metadata URL override
    * `:introspection_endpoint` — token introspection URL override (RFC 7662)
    * `:authorization_endpoint` — authorization URL override
    * `:identity_providers` — IdPs advertised in `GET /_matrix/client/v3/login`
    * `:account_management_url` — account management URL for `.well-known/matrix/client`
  """

  @default_redirect_path "/_matrix/client/v3/login/sso/callback"
  @default_scopes ~w(openid profile email)

  @type identity_provider :: %{
          required(:id) => String.t(),
          required(:name) => String.t(),
          optional(:icon) => String.t(),
          optional(:brand) => String.t()
        }

  @doc """
  Returns whether the required OIDC settings are present.
  """
  @spec configured?() :: boolean()
  def configured? do
    not is_nil(config(:issuer)) and not is_nil(config(:client_id))
  end

  @doc """
  Returns the OIDC issuer URL.
  """
  @spec issuer() :: String.t() | nil
  def issuer, do: config(:issuer)

  @doc """
  Returns the OAuth 2.0 client identifier.
  """
  @spec client_id() :: String.t() | nil
  def client_id, do: config(:client_id)

  @doc """
  Returns the OAuth 2.0 client secret, if configured.
  """
  @spec client_secret() :: String.t() | nil
  def client_secret, do: config(:client_secret)

  @doc """
  Returns the requested OIDC scopes.
  """
  @spec scopes() :: [String.t()]
  def scopes do
    case config(:scopes) do
      nil -> @default_scopes
      scopes when is_list(scopes) -> scopes
    end
  end

  @doc """
  Returns the SSO callback path on this homeserver.
  """
  @spec redirect_path() :: String.t()
  def redirect_path do
    config(:redirect_path) || @default_redirect_path
  end

  @doc """
  Returns the OAuth 2.0 redirect URI registered with the OIDC provider.
  """
  @spec redirect_uri() :: String.t()
  def redirect_uri do
    case config(:redirect_uri) do
      nil -> Mim.WellKnown.client_base_url() <> redirect_path()
      uri -> uri
    end
  end

  @doc """
  Returns the OpenID Provider Metadata discovery URL.
  """
  @spec discovery_document_url() :: String.t() | nil
  def discovery_document_url do
    case config(:discovery_url) do
      nil ->
        case issuer() do
          nil -> nil
          issuer -> String.trim_trailing(issuer, "/") <> "/.well-known/openid-configuration"
        end

      url ->
        url
    end
  end

  @doc """
  Returns identity providers advertised in the Matrix login flows response.
  """
  @spec identity_providers() :: [identity_provider()]
  def identity_providers do
    config(:identity_providers) || []
  end

  @doc """
  Returns the token introspection endpoint URL, if configured directly.
  """
  @spec introspection_endpoint() :: String.t() | nil
  def introspection_endpoint, do: config(:introspection_endpoint)

  @doc """
  Returns the authorization endpoint URL, if configured directly.
  """
  @spec authorization_endpoint() :: String.t() | nil
  def authorization_endpoint, do: config(:authorization_endpoint)

  @doc """
  Returns the account management URL advertised in client discovery.
  """
  @spec account_management_url() :: String.t() | nil
  def account_management_url, do: config(:account_management_url)

  defp config(key) do
    Application.get_env(:mim, :oidc, []) |> Keyword.get(key)
  end
end
