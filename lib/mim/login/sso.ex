defmodule Mim.Login.Sso do
  @moduledoc """
  SSO redirect handling for `GET /_matrix/client/v3/login/sso/redirect`.
  """

  alias Mim.Matrix.Errors
  alias Mim.Oidc
  alias Mim.Oidc.Discovery

  @valid_actions ~w(login register)
  @pkce_verifier_length 48

  @type session_data :: %{
          required(:state) => String.t(),
          required(:nonce) => String.t(),
          required(:redirect_url) => String.t(),
          required(:code_verifier) => String.t() | nil,
          required(:idp_id) => String.t() | nil,
          required(:action) => String.t() | nil
        }

  @doc """
  Builds an OIDC authorization redirect for the Matrix SSO login flow.

  Returns the redirect URL and session data that must be stored until the
  SSO callback completes.
  """
  @spec redirect_request(map(), String.t() | nil) ::
          {:ok, %{location: String.t(), session: session_data()}}
          | {:error, :bad_request | :not_found | :server_error, map()}
  def redirect_request(params, idp_id \\ nil) do
    with {:ok, redirect_url} <- fetch_redirect_url(params),
         {:ok, idp_id} <- resolve_idp_id(idp_id),
         :ok <- ensure_oidc_configured(),
         {:ok, metadata} <- Discovery.metadata(),
         {:ok, authorization_endpoint} <- authorization_endpoint(metadata),
         {:ok, session} <- build_session(redirect_url, idp_id, action(params), metadata),
         {:ok, location} <- build_authorization_url(authorization_endpoint, session) do
      {:ok, %{location: location, session: session}}
    end
  end

  defp fetch_redirect_url(%{"redirectUrl" => redirect_url}) when is_binary(redirect_url) do
    validate_redirect_url(redirect_url)
  end

  defp fetch_redirect_url(_params) do
    {:error, :bad_request, Errors.invalid_param("Missing redirectUrl")}
  end

  defp validate_redirect_url(redirect_url) do
    with {:ok, uri} <- parse_redirect_url(redirect_url),
         :ok <- ensure_no_userinfo(uri),
         :ok <- ensure_host_for_http(uri) do
      {:ok, redirect_url}
    else
      {:error, :invalid} ->
        {:error, :bad_request, Errors.invalid_param("Invalid redirectUrl")}
    end
  end

  defp parse_redirect_url(redirect_url) do
    case URI.parse(redirect_url) do
      %URI{scheme: scheme} when scheme in [nil, ""] ->
        {:error, :invalid}

      %URI{} = uri ->
        {:ok, uri}
    end
  end

  defp ensure_no_userinfo(%URI{userinfo: userinfo}) when userinfo in [nil, ""], do: :ok
  defp ensure_no_userinfo(_uri), do: {:error, :invalid}

  defp ensure_host_for_http(%URI{scheme: scheme, host: host})
       when scheme in ["http", "https"] and is_binary(host) and host != "" do
    :ok
  end

  defp ensure_host_for_http(%URI{scheme: scheme}) when scheme not in ["http", "https"], do: :ok
  defp ensure_host_for_http(_uri), do: {:error, :invalid}

  defp action(params) do
    params
    |> Map.get("action")
    |> normalize_action()
    |> case do
      nil -> Map.get(params, "org.matrix.msc3824.action") |> normalize_action()
      action -> action
    end
  end

  defp normalize_action(action) when action in @valid_actions, do: action
  defp normalize_action(_action), do: nil

  defp resolve_idp_id(nil) do
    case Oidc.identity_providers() do
      [%{id: id} | _] -> {:ok, id}
      [] -> {:ok, "oidc"}
    end
  end

  defp resolve_idp_id(idp_id) do
    if idp_id in Enum.map(Oidc.identity_providers(), & &1.id) do
      {:ok, idp_id}
    else
      {:error, :not_found, Errors.not_found("Unknown identity provider")}
    end
  end

  defp ensure_oidc_configured do
    if Oidc.configured?() do
      :ok
    else
      {:error, :not_found, Errors.not_found("OIDC is not configured on this homeserver")}
    end
  end

  defp authorization_endpoint(metadata) do
    case Oidc.authorization_endpoint() do
      endpoint when is_binary(endpoint) and endpoint != "" ->
        {:ok, endpoint}

      _ ->
        case Map.get(metadata, "authorization_endpoint") do
          endpoint when is_binary(endpoint) and endpoint != "" ->
            {:ok, endpoint}

          _ ->
            {:error, :server_error, oidc_unavailable()}
        end
    end
  end

  defp build_session(redirect_url, idp_id, action, metadata) do
    state = random_token()
    nonce = random_token()

    code_verifier =
      if pkce_supported?(metadata) do
        pkce_code_verifier()
      end

    {:ok,
     %{
       state: state,
       nonce: nonce,
       redirect_url: redirect_url,
       code_verifier: code_verifier,
       idp_id: idp_id,
       action: action
     }}
  end

  defp build_authorization_url(authorization_endpoint, session) do
    query =
      %{
        "client_id" => Oidc.client_id(),
        "response_type" => "code",
        "redirect_uri" => Oidc.redirect_uri(),
        "scope" => Enum.join(Oidc.scopes(), " "),
        "state" => session.state,
        "nonce" => session.nonce
      }
      |> maybe_put_pkce(session.code_verifier)
      |> URI.encode_query()

    {:ok, authorization_endpoint <> "?" <> query}
  end

  defp maybe_put_pkce(query, nil), do: query

  defp maybe_put_pkce(query, code_verifier) do
    query
    |> Map.put("code_challenge_method", "S256")
    |> Map.put("code_challenge", pkce_code_challenge(code_verifier))
  end

  defp pkce_supported?(%{"code_challenge_methods_supported" => methods}) when is_list(methods) do
    "S256" in methods
  end

  defp pkce_supported?(_metadata), do: false

  defp pkce_code_verifier do
    @pkce_verifier_length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp pkce_code_challenge(code_verifier) do
    :crypto.hash(:sha256, code_verifier)
    |> Base.url_encode64(padding: false)
  end

  defp random_token do
    32
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64(padding: false)
  end

  defp oidc_unavailable do
    %{
      "errcode" => "M_UNKNOWN",
      "error" => "OIDC authorization is not available on this homeserver"
    }
  end
end
