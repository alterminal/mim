defmodule Mim.Room do
  @moduledoc """
  Builds room-related Matrix client API responses.
  """

  alias Mim.Accounts.Account
  alias Mim.Matrix.Errors
  alias Mim.Rooms
  alias Mim.Rooms.Room, as: RoomSchema

  @supported_room_versions ["10"]
  @default_room_version "10"

  @doc """
  Creates a room for `POST /_matrix/client/v3/createRoom`.
  """
  @spec create(Account.t(), map()) ::
          {:ok, map()}
          | {:error, map()}
          | {:error, Ecto.Changeset.t()}
          | {:error, :unsupported_room_version, String.t()}
  def create(%Account{} = creator, params) when is_map(params) do
    with {:ok, attrs} <- parse_params(params),
         {:ok, %RoomSchema{} = room} <- Rooms.create_room(creator, attrs) do
      {:ok, %{"room_id" => room.room_id}}
    end
  end

  defp parse_params(params) do
    with {:ok, visibility} <- parse_visibility(params),
         {:ok, room_version} <- parse_room_version(params) do
      attrs =
        %{visibility: visibility, room_version: room_version}
        |> maybe_put(:name, params["name"])
        |> maybe_put(:topic, params["topic"])

      {:ok, attrs}
    end
  end

  defp parse_visibility(%{"visibility" => visibility}), do: parse_visibility_value(visibility)
  defp parse_visibility(%{"preset" => "public_chat"}), do: {:ok, :public}
  defp parse_visibility(_params), do: {:ok, :private}

  defp parse_visibility_value("public"), do: {:ok, :public}
  defp parse_visibility_value("private"), do: {:ok, :private}

  defp parse_visibility_value(value) do
    {:error, Errors.invalid_param("Invalid visibility: #{inspect(value)}")}
  end

  defp parse_room_version(params) do
    case Map.get(params, "room_version", @default_room_version) do
      version when version in @supported_room_versions ->
        {:ok, version}

      version ->
        {:error, :unsupported_room_version, version}
    end
  end

  defp maybe_put(attrs, _key, nil), do: attrs
  defp maybe_put(attrs, key, value), do: Map.put(attrs, key, value)
end
