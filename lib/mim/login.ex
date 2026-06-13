defmodule Mim.Login do
  @moduledoc """
  Builds Matrix client login flow responses for this homeserver.
  """

  @sso_type "m.login.sso"
  @token_type "m.login.token"
  @oauth_aware_preferred_field "oauth_aware_preferred"
  @delegated_oidc_compatibility_field "org.matrix.msc3824.delegated_oidc_compatibility"

  @doc """
  Returns the login flows document for `GET /_matrix/client/v3/login`.
  """
  @spec flows() :: map()
  def flows do
    %{"flows" => [sso_flow(), token_flow()]}
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
    oidc_config()
    |> Keyword.get(:identity_providers, [])
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

  defp oidc_config do
    Application.get_env(:mim, :oidc, [])
  end
end
