defmodule Mim.WellKnownTest do
  use ExUnit.Case, async: true

  alias Mim.WellKnown

  test "client_discovery/0 returns homeserver base URL" do
    assert %{"m.homeserver" => %{"base_url" => "http://localhost:4002"}} =
             WellKnown.client_discovery()
  end

  test "server_discovery/0 returns federation delegate" do
    assert %{"m.server" => "localhost:8448"} = WellKnown.server_discovery()
  end
end
