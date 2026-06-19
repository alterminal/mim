defmodule Mim.WellKnownTest do
  use ExUnit.Case, async: false

  alias Mim.WellKnown

  setup do
    original_oidc = Application.get_env(:mim, :oidc, [])
    original_matrix = Application.get_env(:mim, :matrix, [])

    on_exit(fn ->
      Application.put_env(:mim, :oidc, original_oidc)
      Application.put_env(:mim, :matrix, original_matrix)
    end)

    :ok
  end

  test "client_discovery/0 uses configured client_base_url" do
    original = Application.get_env(:mim, :matrix, [])

    Application.put_env(
      :mim,
      :matrix,
      Keyword.put(original, :client_base_url, "https://matrix.example.com")
    )

    assert %{
             "m.homeserver" => %{"base_url" => "https://matrix.example.com"},
             "m.identity_server" => %{"base_url" => "https://matrix.example.com"}
           } = WellKnown.client_discovery()
  end

  test "client_discovery/0 returns homeserver base URL and MSC2965 authentication" do
    assert %{
             "m.homeserver" => %{"base_url" => "http://localhost:4002"},
             "m.identity_server" => %{"base_url" => "http://localhost:4002"},
             "org.matrix.msc2965.authentication" => %{"issuer" => "https://idp.example.com"}
           } = WellKnown.client_discovery()
  end

  test "client_discovery/0 includes account management URL when configured" do
    original = Application.get_env(:mim, :oidc, [])

    Application.put_env(
      :mim,
      :oidc,
      Keyword.put(original, :account_management_url, "https://idp.example.com/account")
    )

    assert %{
             "org.matrix.msc2965.authentication" => %{
               "issuer" => "https://idp.example.com",
               "account" => "https://idp.example.com/account"
             }
           } = WellKnown.client_discovery()
  end

  test "client_discovery/0 omits org.matrix.msc2965.authentication when OIDC is not configured" do
    original = Application.get_env(:mim, :oidc, [])
    Application.put_env(:mim, :oidc, Keyword.merge(original, issuer: nil, client_id: nil))

    assert %{
             "m.homeserver" => %{"base_url" => "http://localhost:4002"},
             "m.identity_server" => %{"base_url" => "http://localhost:4002"}
           } = WellKnown.client_discovery()
  end

  test "client_discovery/0 uses configured identity_server_base_url" do
    original = Application.get_env(:mim, :matrix, [])

    Application.put_env(
      :mim,
      :matrix,
      original
      |> Keyword.put(:client_base_url, "https://matrix.example.com")
      |> Keyword.put(:identity_server_base_url, "https://identity.example.com")
    )

    assert %{
             "m.homeserver" => %{"base_url" => "https://matrix.example.com"},
             "m.identity_server" => %{"base_url" => "https://identity.example.com"}
           } = WellKnown.client_discovery()
  end

  test "server_discovery/0 returns federation delegate" do
    assert %{"m.server" => "localhost:8448"} = WellKnown.server_discovery()
  end
end
