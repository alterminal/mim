defmodule Mim.Oidc.IntrospectionTest do
  use ExUnit.Case, async: true

  alias Mim.Oidc.Introspection

  test "introspect/1 returns active token claims" do
    Req.Test.stub(Mim.Oidc.HTTP, fn conn ->
      assert conn.request_path == "/oauth2/introspect"

      assert {"authorization", "Basic " <> credentials} =
               List.keyfind(conn.req_headers, "authorization", 0)

      assert Base.decode64!(credentials) == "mim-test:test-secret"

      Req.Test.json(conn, %{
        "active" => true,
        "sub" => "user-subject",
        "iss" => "https://idp.example.com",
        "username" => "alice"
      })
    end)

    assert {:ok, claims} = Introspection.introspect("oidc-access-token")

    assert claims["sub"] == "user-subject"
    assert claims["iss"] == "https://idp.example.com"
    assert claims["username"] == "alice"
  end

  test "introspect/1 returns inactive for rejected tokens" do
    Req.Test.stub(Mim.Oidc.HTTP, fn conn ->
      Req.Test.json(conn, %{"active" => false})
    end)

    assert {:error, :inactive} = Introspection.introspect("bad-token")
  end

  test "introspect/1 uses configured issuer when response omits iss" do
    Req.Test.stub(Mim.Oidc.HTTP, fn conn ->
      Req.Test.json(conn, %{"active" => true, "sub" => "user-subject"})
    end)

    assert {:ok, %{"sub" => "user-subject", "iss" => "https://idp.example.com"}} =
             Introspection.introspect("oidc-access-token")
  end
end
