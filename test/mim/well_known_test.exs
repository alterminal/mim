defmodule Mim.WellKnownTest do
  use ExUnit.Case, async: false

  alias Mim.WellKnown

  setup do
    original = Application.get_env(:mim, :oidc, [])

    on_exit(fn -> Application.put_env(:mim, :oidc, original) end)

    :ok
  end

  test "client_discovery/0 returns homeserver base URL and OIDC authentication" do
    assert %{
             "m.homeserver" => %{"base_url" => "http://localhost:4002"},
             "m.authentication" => %{"issuer" => "https://idp.example.com"}
           } = WellKnown.client_discovery()
  end

  test "client_discovery/0 omits m.authentication when OIDC is not configured" do
    original = Application.get_env(:mim, :oidc, [])
    Application.put_env(:mim, :oidc, Keyword.merge(original, issuer: nil, client_id: nil))

    assert %{"m.homeserver" => %{"base_url" => "http://localhost:4002"}} =
             WellKnown.client_discovery()
  end

  test "server_discovery/0 returns federation delegate" do
    assert %{"m.server" => "localhost:8448"} = WellKnown.server_discovery()
  end
end
