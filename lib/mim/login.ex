defmodule Mim.Login do
  @moduledoc """
  Builds Matrix client login flow responses for this homeserver.
  """

  alias Mim.Accounts
  alias Mim.Matrix.Errors
  alias Mim.Oidc.Introspection
  alias Mim.WellKnown

  @sso_type "m.login.sso"
  @token_type "m.login.token"
  @oauth_aware_preferred_field "oauth_aware_preferred"
  @delegated_oidc_compatibility_field "org.matrix.msc3824.delegated_oidc_compatibility"
  @device_id_regex ~r/^[a-zA-Z0-9._=-]+$/

  @doc """
  Returns the login flows document for `GET /_matrix/client/v3/login`.
  """
  @spec flows() :: map()
  def flows do
    %{"flows" => [sso_flow(), token_flow()]}
  end

  @doc """
  Authenticates a client using `POST /_matrix/client/v3/login`.

  Supports `m.login.token` by introspecting the supplied token at the
  configured OIDC provider's introspection endpoint.
  """
  @spec login(map()) :: {:ok, map()} | {:error, term()}
  def login(%{"type" => @token_type} = params) do
    token = Map.get(params, "token")
    device_id = Map.get(params, "device_id")

    cond do
      not is_binary(token) or token == "" ->
        {:error, {:bad_request, Errors.invalid_param("Missing token")}}

      not valid_device_id?(device_id) ->
        {:error, {:forbidden, Errors.forbidden("Invalid device ID")}}

      true ->
        login_with_introspected_token(token, device_id)
    end
  end

  def login(%{"type" => type}) do
    {:error, {:bad_request, unknown_login_type(type)}}
  end

  def login(_params) do
    {:error, {:bad_request, unknown_login_type(nil)}}
  end

  defp login_with_introspected_token(token, device_id) do
    with {:ok, claims} <- Introspection.introspect(token),
         {:ok, account} <- Accounts.fetch_or_create_account_for_oidc(claims),
         {:ok, access_token} <- Accounts.issue_access_token(account) do
      {:ok, login_response(account, access_token, device_id || generate_device_id())}
    else
      {:error, :inactive} ->
        {:error, {:forbidden, Errors.forbidden("Invalid token")}}

      {:error, :invalid_localpart} ->
        {:error, {:forbidden, Errors.forbidden("Invalid token")}}

      {:error, :not_configured} ->
        {:error, {:server_error, oidc_not_configured()}}

      {:error, :no_endpoint} ->
        {:error, {:server_error, introspection_unavailable()}}

      {:error, :request_failed} ->
        {:error, {:server_error, introspection_failed()}}

      {:error, :invalid_response} ->
        {:error, {:server_error, introspection_failed()}}

      {:error, %Ecto.Changeset{}} ->
        {:error, {:server_error, account_provisioning_failed()}}

      {:error, _} = error ->
        error
    end
  end

  defp login_response(account, access_token, device_id) do
    %{
      "user_id" => account.mxid,
      "access_token" => access_token.token,
      "device_id" => device_id,
      "well_known" => %{
        "m.homeserver" => %{"base_url" => WellKnown.client_base_url()}
      }
    }
  end

  defp valid_device_id?(nil), do: true

  defp valid_device_id?(device_id) when is_binary(device_id) do
    device_id != "" and String.length(device_id) <= 255 and
      Regex.match?(@device_id_regex, device_id)
  end

  defp valid_device_id?(_), do: false

  defp generate_device_id do
    10
    |> :crypto.strong_rand_bytes()
    |> Base.encode32(padding: false, case: :upper)
    |> binary_part(0, 10)
  end

  defp unknown_login_type(type) do
    message =
      case type do
        nil -> "Missing login type"
        type -> "Unknown login type #{type}"
      end

    %{"errcode" => "M_UNKNOWN", "error" => message}
  end

  defp oidc_not_configured do
    %{"errcode" => "M_UNKNOWN", "error" => "OIDC is not configured on this homeserver"}
  end

  defp introspection_unavailable do
    %{
      "errcode" => "M_UNKNOWN",
      "error" => "OIDC token introspection is not available on this homeserver"
    }
  end

  defp introspection_failed do
    %{"errcode" => "M_UNKNOWN", "error" => "Token introspection failed"}
  end

  defp account_provisioning_failed do
    %{"errcode" => "M_UNKNOWN", "error" => "Failed to provision account"}
  end

  defp sso_flow do
    %{
      "type" => @sso_type,
      @oauth_aware_preferred_field => true,
      @delegated_oidc_compatibility_field => true,
      "identity_providers" => identity_providers()
    }
  end

  defp token_flow do
    %{"type" => @token_type}
  end

  defp identity_providers do
    Mim.Oidc.identity_providers()
    |> Enum.map(&identity_provider/1)
  end

  defp identity_provider(%{id: id, name: name} = provider) do
    %{"id" => id, "name" => name}
    |> maybe_put_identity_provider_field(provider, :icon, "icon")
    |> maybe_put_identity_provider_field(provider, :brand, "brand")
  end

  defp maybe_put_identity_provider_field(map, provider, key, json_key) do
    case Map.get(provider, key) do
      nil -> map
      value -> Map.put(map, json_key, value)
    end
  end
end
