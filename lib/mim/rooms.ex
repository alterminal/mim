defmodule Mim.Rooms do
  @moduledoc """
  Room management for Matrix clients.
  """

  import Ecto.Query, warn: false

  alias Mim.Accounts.Account
  alias Mim.Repo
  alias Mim.Rooms.Room
  alias Mim.WellKnown

  @doc """
  Creates a room for the given creator account.
  """
  @spec create_room(Account.t(), map()) :: {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def create_room(%Account{} = creator, attrs \\ %{}) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put_new(:room_id, generate_room_id())
      |> Map.put(:creator_id, creator.id)

    %Room{}
    |> Room.changeset(attrs)
    |> Repo.insert()
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

  defp generate_room_id do
    localpart = 18 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
    "!#{localpart}:#{WellKnown.server_name()}"
  end
end
