defmodule Mim.AuthIssuerTest do
  use ExUnit.Case, async: false

  alias Mim.AuthIssuer

  setup do
    original = Application.get_env(:mim, :oidc, [])

    on_exit(fn -> Application.put_env(:mim, :oidc, original) end)

    :ok
  end

  test "document/0 returns issuer when OIDC is configured" do
    assert {:ok, %{"issuer" => "https://idp.example.com"}} = AuthIssuer.document()
  end

  test "document/0 returns M_NOT_FOUND when OIDC is not configured" do
    original = Application.get_env(:mim, :oidc, [])
    Application.put_env(:mim, :oidc, Keyword.merge(original, issuer: nil, client_id: nil))

    assert {:error, %{"errcode" => "M_NOT_FOUND", "error" => error}} = AuthIssuer.document()
    assert error =~ "OIDC discovery has not been configured"
  end
end
