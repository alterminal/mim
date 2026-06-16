defmodule Mim.Rooms.MembershipTest do
  use Mim.DataCase, async: true

  alias Mim.Accounts
  alias Mim.Rooms
  alias Mim.Rooms.Membership

  setup do
    {:ok, creator} =
      Accounts.create_account(%{
        mxid: "@creator:localhost",
        oidc_sub: "sub-creator",
        oidc_issuer: "https://idp.example.com"
      })

    {:ok, member} =
      Accounts.create_account(%{
        mxid: "@member:localhost",
        oidc_sub: "sub-member",
        oidc_issuer: "https://idp.example.com"
      })

    {:ok, invitee} =
      Accounts.create_account(%{
        mxid: "@invitee:localhost",
        oidc_sub: "sub-invitee",
        oidc_issuer: "https://idp.example.com"
      })

    {:ok, outsider} =
      Accounts.create_account(%{
        mxid: "@outsider:localhost",
        oidc_sub: "sub-outsider",
        oidc_issuer: "https://idp.example.com"
      })

    {:ok, room} = Rooms.create_room(creator, %{name: "Private", visibility: :private})
    {:ok, public_room} = Rooms.create_room(creator, %{name: "Public", visibility: :public})

    %{
      creator: creator,
      member: member,
      invitee: invitee,
      outsider: outsider,
      room: room,
      public_room: public_room
    }
  end

  test "create_room/2 adds creator as a joined member", %{room: room, creator: creator} do
    assert {:ok, %Membership{membership: :join}} = Rooms.fetch_membership(room, creator)
    assert Rooms.joined_member?(room, creator)
  end

  test "joined member can invite another user", %{room: room, creator: creator, invitee: invitee} do
    assert {:ok, %Membership{membership: :invite, invited_by_id: invited_by}} =
             Rooms.invite_user(room, creator, invitee)

    assert invited_by == creator.id
  end

  test "non-member cannot invite users", %{room: room, outsider: outsider, invitee: invitee} do
    assert {:error, :forbidden} = Rooms.invite_user(room, outsider, invitee)
  end

  test "cannot invite a user who is already joined", %{
    room: room,
    creator: creator,
    invitee: invitee
  } do
    assert {:ok, _} = Rooms.invite_user(room, creator, invitee)
    assert {:ok, _} = Rooms.join_room(room, invitee)
    assert {:error, :already_joined} = Rooms.invite_user(room, creator, invitee)
  end

  test "public room can be joined without an invite", %{public_room: room, outsider: outsider} do
    assert {:ok, %Membership{membership: :join}} = Rooms.join_room(room, outsider)
  end

  test "private room requires an invite before joining", %{
    room: room,
    creator: creator,
    invitee: invitee
  } do
    assert {:error, :forbidden} = Rooms.join_room(room, invitee)
    assert {:ok, _} = Rooms.invite_user(room, creator, invitee)
    assert {:ok, %Membership{membership: :join}} = Rooms.join_room(room, invitee)
  end

  test "joining an already joined room is idempotent", %{room: room, creator: creator} do
    assert {:ok, first} = Rooms.join_room(room, creator)
    assert {:ok, second} = Rooms.join_room(room, creator)
    assert first.id == second.id
  end
end
