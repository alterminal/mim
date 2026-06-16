defmodule Mim.Rooms do
  @moduledoc """
  Room management for Matrix clients.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Mim.Accounts.Account
  alias Mim.Repo
  alias Mim.Rooms.Membership
  alias Mim.Rooms.Room
  alias Mim.WellKnown

  @doc """
  Creates a room for the given creator account and adds the creator as a joined member.
  """
  @spec create_room(Account.t(), map()) :: {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def create_room(%Account{} = creator, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:room_id, generate_room_id())
      |> Map.put(:creator_id, creator.id)

    Multi.new()
    |> Multi.insert(:room, Room.changeset(%Room{}, attrs))
    |> Multi.insert(:membership, fn %{room: room} ->
      Membership.changeset(%Membership{}, %{
        room_id: room.id,
        account_id: creator.id,
        membership: :join
      })
    end)
    |> Repo.transaction()
    |> case do
      {:ok, %{room: room}} -> {:ok, room}
      {:error, :room, changeset, _} -> {:error, changeset}
      {:error, :membership, changeset, _} -> {:error, changeset}
    end
  end

  @doc """
  Fetches a room by its Matrix room ID.
  """
  @spec fetch_room_by_room_id(String.t()) :: {:ok, Room.t()} | {:error, :not_found}
  def fetch_room_by_room_id(room_id) when is_binary(room_id) do
    case Repo.get_by(Room, room_id: room_id) do
      %Room{} = room -> {:ok, room}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Fetches the membership record for an account in a room.
  """
  @spec fetch_membership(Room.t(), Account.t()) :: {:ok, Membership.t()} | {:error, :not_found}
  def fetch_membership(%Room{} = room, %Account{} = account) do
    case Repo.get_by(Membership, room_id: room.id, account_id: account.id) do
      %Membership{} = membership -> {:ok, membership}
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Returns whether the account is a joined member of the room.
  """
  @spec joined_member?(Room.t(), Account.t()) :: boolean()
  def joined_member?(%Room{} = room, %Account{} = account) do
    case fetch_membership(room, account) do
      {:ok, %Membership{membership: :join}} -> true
      _ -> false
    end
  end

  @doc """
  Invites an account to a room.

  The inviter must be a joined member. Returns an error if the invitee is already joined.
  """
  @spec invite_user(Room.t(), Account.t(), Account.t()) ::
          {:ok, Membership.t()}
          | {:error, :forbidden | :already_joined | Ecto.Changeset.t()}
  def invite_user(%Room{} = room, %Account{} = inviter, %Account{} = invitee) do
    cond do
      not joined_member?(room, inviter) ->
        {:error, :forbidden}

      joined_member?(room, invitee) ->
        {:error, :already_joined}

      true ->
        upsert_membership(room, invitee, :invite, inviter.id)
    end
  end

  @doc """
  Joins an account to a room.

  Public rooms can be joined directly. Private rooms require a pending invite.
  """
  @spec join_room(Room.t(), Account.t()) ::
          {:ok, Membership.t()} | {:error, :forbidden | Ecto.Changeset.t()}
  def join_room(%Room{} = room, %Account{} = account) do
    case fetch_membership(room, account) do
      {:ok, %Membership{membership: :join} = membership} ->
        {:ok, membership}

      {:ok, %Membership{membership: :invite}} ->
        upsert_membership(room, account, :join)

      {:ok, %Membership{}} ->
        {:error, :forbidden}

      {:error, :not_found} ->
        if room.visibility == :public do
          upsert_membership(room, account, :join)
        else
          {:error, :forbidden}
        end
    end
  end

  defp upsert_membership(room, account, membership, invited_by_id \\ nil) do
    attrs = %{
      room_id: room.id,
      account_id: account.id,
      membership: membership,
      invited_by_id: invited_by_id
    }

    %Membership{}
    |> Membership.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:membership, :invited_by_id, :updated_at]},
      conflict_target: [:room_id, :account_id],
      returning: true
    )
  end

  defp generate_room_id do
    localpart = 18 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    "!#{localpart}:#{WellKnown.server_name()}"
  end
end
