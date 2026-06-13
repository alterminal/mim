defmodule Mim.WellKnown.ClientTest do
  use ExUnit.Case, async: true

  alias Mim.WellKnown.Client

  describe "discover_client/2" do
    test "returns homeserver and identity server URLs" do
      Req.Test.stub(Mim.WellKnown.HTTP, fn conn ->
        assert conn.request_path == "/.well-known/matrix/client"

        Req.Test.json(conn, %{
          "m.homeserver" => %{"base_url" => "https://matrix.example.com"},
          "m.identity_server" => %{"base_url" => "https://identity.example.com"}
        })
      end)

      assert {:ok,
              %{
                homeserver_base_url: "https://matrix.example.com",
                identity_server_base_url: "https://identity.example.com"
              }} = Client.discover_client("example.com")
    end

    test "returns error when homeserver is missing" do
      Req.Test.stub(Mim.WellKnown.HTTP, fn conn ->
        Req.Test.json(conn, %{})
      end)

      assert {:error, :invalid_response} = Client.discover_client("example.com")
    end

    test "returns not_found for 404 responses" do
      Req.Test.stub(Mim.WellKnown.HTTP, fn conn ->
        Plug.Conn.send_resp(conn, 404, "")
      end)

      assert {:error, :not_found} = Client.discover_client("example.com")
    end
  end

  describe "discover_server/2" do
    test "parses host and port from m.server" do
      Req.Test.stub(Mim.WellKnown.HTTP, fn conn ->
        assert conn.request_path == "/.well-known/matrix/server"

        Req.Test.json(conn, %{"m.server" => "federation.example.com:8448"})
      end)

      assert {:ok, %{server: "federation.example.com", port: 8448}} =
               Client.discover_server("example.com")
    end

    test "parses host without explicit port" do
      Req.Test.stub(Mim.WellKnown.HTTP, fn conn ->
        Req.Test.json(conn, %{"m.server" => "federation.example.com"})
      end)

      assert {:ok, %{server: "federation.example.com", port: nil}} =
               Client.discover_server("example.com")
    end

    test "returns error for invalid delegate" do
      Req.Test.stub(Mim.WellKnown.HTTP, fn conn ->
        Req.Test.json(conn, %{"m.server" => "bad:port"})
      end)

      assert {:error, :invalid_response} = Client.discover_server("example.com")
    end
  end
end
