defmodule Mim.Oidc.DiscoveryTest do
  use ExUnit.Case, async: false

  alias Mim.Oidc
  alias Mim.Oidc.Discovery

  setup do
    original = Application.get_env(:mim, :oidc, [])

    on_exit(fn -> Application.put_env(:mim, :oidc, original) end)

    :ok
  end

  test "introspection_endpoint/0 returns configured endpoint" do
    assert {:ok, "https://idp.example.com/oauth2/introspect"} =
             Discovery.introspection_endpoint()
  end

  test "introspection_endpoint/0 discovers endpoint from provider metadata" do
    Application.put_env(
      :mim,
      :oidc,
      Keyword.merge(Application.get_env(:mim, :oidc, []), introspection_endpoint: nil)
    )

    Req.Test.stub(Mim.Oidc.HTTP, fn conn ->
      assert conn.request_path == "/.well-known/openid-configuration"

      Req.Test.json(conn, %{
        "introspection_endpoint" => "https://idp.example.com/oauth2/introspect"
      })
    end)

    assert {:ok, "https://idp.example.com/oauth2/introspect"} =
             Discovery.introspection_endpoint()
  end

  test "introspection_endpoint/0 returns not_configured when OIDC is disabled" do
    Application.put_env(
      :mim,
      :oidc,
      Keyword.merge(Application.get_env(:mim, :oidc, []),
        issuer: nil,
        client_id: nil,
        introspection_endpoint: nil
      )
    )

    assert {:error, :not_configured} = Discovery.introspection_endpoint()
    refute Oidc.configured?()
  end
end
