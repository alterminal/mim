defmodule Mim.Rooms.RoomTest do
  use Mim.DataCase, async: true

  alias Mim.Accounts
  alias Mim.Rooms
  alias Mim.Rooms.Room

  setup do
    {:ok, account} =
      Accounts.create_account(%{
        mxid: "@alice:localhost",
        oidc_sub: "sub-1",
        oidc_issuer: "https://idp.example.com"
      })

    %{account: account}
  end

  test "create_room/2 creates a room with a generated room_id", %{account: account} do
    assert {:ok, %Room{} = room} = Rooms.create_room(account, %{name: "General"})
    assert room.name == "General"
    assert room.creator_id == account.id
    assert room.visibility == :private
    assert room.room_version == "10"
    assert room.room_id =~ ~r/^![a-z0-9._=\/-]+:localhost$/i
  end

  test "create_room/2 accepts an explicit room_id", %{account: account} do
    room_id = "!general:localhost"

    assert {:ok, %Room{} = room} =
             Rooms.create_room(account, %{room_id: room_id, visibility: :public})

    assert room.room_id == room_id
    assert room.visibility == :public
  end

  test "changeset validates room_id format", %{account: account} do
    changeset =
      %Room{}
      |> Room.changeset(%{room_id: "invalid", creator_id: account.id})

    assert "must be a valid Matrix room ID (!room:server)" in errors_on(changeset).room_id
  end

  test "fetch_room_by_room_id/1 returns the room", %{account: account} do
    room_id = "!fetch-me:localhost"
    {:ok, _} = Rooms.create_room(account, %{room_id: room_id})

    assert {:ok, %Room{room_id: ^room_id}} = Rooms.fetch_room_by_room_id(room_id)
    assert {:error, :not_found} = Rooms.fetch_room_by_room_id("!missing:localhost")
  end
end
