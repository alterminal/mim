defmodule Mim.RoomTest do
  use Mim.DataCase, async: true

  alias Mim.Accounts
  alias Mim.Room

  setup do
    {:ok, account} =
      Accounts.create_account(%{
        mxid: "@alice:localhost",
        oidc_sub: "sub-1",
        oidc_issuer: "https://idp.example.com"
      })

    %{account: account}
  end

  test "create/2 returns room_id for an empty request", %{account: account} do
    assert {:ok, %{"room_id" => room_id}} = Room.create(account, %{})
    assert room_id =~ ~r/^![a-z0-9._=\/-]+:localhost$/i
  end

  test "create/2 accepts name, topic, and visibility", %{account: account} do
    assert {:ok, %{"room_id" => room_id}} =
             Room.create(account, %{
               "name" => "General",
               "topic" => "Off-topic",
               "visibility" => "public"
             })

    assert {:ok, room} = Mim.Rooms.fetch_room_by_room_id(room_id)
    assert room.name == "General"
    assert room.topic == "Off-topic"
    assert room.visibility == :public
  end

  test "create/2 maps public_chat preset to public visibility", %{account: account} do
    assert {:ok, %{"room_id" => room_id}} =
             Room.create(account, %{"preset" => "public_chat"})

    assert {:ok, room} = Mim.Rooms.fetch_room_by_room_id(room_id)
    assert room.visibility == :public
  end

  test "create/2 prefers visibility over preset", %{account: account} do
    assert {:ok, %{"room_id" => room_id}} =
             Room.create(account, %{
               "preset" => "public_chat",
               "visibility" => "private"
             })

    assert {:ok, room} = Mim.Rooms.fetch_room_by_room_id(room_id)
    assert room.visibility == :private
  end

  test "create/2 rejects invalid visibility", %{account: account} do
    assert {:error, %{"errcode" => "M_INVALID_PARAM"}} =
             Room.create(account, %{"visibility" => "secret"})
  end

  test "create/2 rejects unsupported room versions", %{account: account} do
    assert {:error, :unsupported_room_version, "11"} =
             Room.create(account, %{"room_version" => "11"})
  end
end
