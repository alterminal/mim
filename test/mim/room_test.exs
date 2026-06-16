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

  test "create/2 adds creator as a joined member", %{account: account} do
    assert {:ok, %{"room_id" => room_id}} = Room.create(account, %{})
    assert {:ok, room} = Mim.Rooms.fetch_room_by_room_id(room_id)
    assert Mim.Rooms.joined_member?(room, account)
  end

  test "invite/3 invites a local user to a room", %{account: account} do
    {:ok, invitee} =
      Accounts.create_account(%{
        mxid: "@bob:localhost",
        oidc_sub: "sub-bob",
        oidc_issuer: "https://idp.example.com"
      })

    assert {:ok, %{"room_id" => room_id}} = Room.create(account, %{})
    assert {:ok, %{}} = Room.invite(account, room_id, %{"user_id" => invitee.mxid})

    assert {:ok, room} = Mim.Rooms.fetch_room_by_room_id(room_id)

    assert {:ok, %Mim.Rooms.Membership{membership: :invite}} =
             Mim.Rooms.fetch_membership(room, invitee)
  end

  test "invite/3 rejects missing user_id", %{account: account} do
    assert {:ok, %{"room_id" => room_id}} = Room.create(account, %{})
    assert {:error, %{"errcode" => "M_INVALID_PARAM"}} = Room.invite(account, room_id, %{})
  end

  test "invite/3 rejects unknown room", %{account: account} do
    assert {:error, :not_found} =
             Room.invite(account, "!missing:localhost", %{"user_id" => account.mxid})
  end

  test "invite/3 rejects remote users", %{account: account} do
    assert {:ok, %{"room_id" => room_id}} = Room.create(account, %{})

    assert {:error, %{"errcode" => "M_INVALID_PARAM", "error" => message}} =
             Room.invite(account, room_id, %{"user_id" => "@remote:other.server"})

    assert message =~ "homeserver"
  end

  test "join/2 joins a public room", %{account: account} do
    {:ok, joiner} =
      Accounts.create_account(%{
        mxid: "@joiner:localhost",
        oidc_sub: "sub-joiner",
        oidc_issuer: "https://idp.example.com"
      })

    assert {:ok, %{"room_id" => room_id}} =
             Room.create(account, %{"visibility" => "public"})

    assert {:ok, %{"room_id" => ^room_id}} = Room.join(joiner, room_id)
  end

  test "join/2 requires an invite for private rooms", %{account: account} do
    {:ok, invitee} =
      Accounts.create_account(%{
        mxid: "@guest:localhost",
        oidc_sub: "sub-guest",
        oidc_issuer: "https://idp.example.com"
      })

    assert {:ok, %{"room_id" => room_id}} = Room.create(account, %{"visibility" => "private"})
    assert {:error, :forbidden} = Room.join(invitee, room_id)
    assert {:ok, %{}} = Room.invite(account, room_id, %{"user_id" => invitee.mxid})
    assert {:ok, %{"room_id" => ^room_id}} = Room.join(invitee, room_id)
  end

  test "join/2 rejects unknown room", %{account: account} do
    assert {:error, :not_found} = Room.join(account, "!missing:localhost")
  end
end
