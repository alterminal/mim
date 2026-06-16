defmodule Mim.Room do
  @moduledoc """
  Builds room-related Matrix client API responses.
  """

  alias Mim.Accounts
  alias Mim.Accounts.Account
  alias Mim.Matrix.Errors
  alias Mim.Rooms
  alias Mim.Rooms.Room, as: RoomSchema
  alias Mim.WellKnown

  @supported_room_versions ["10"]
  @default_room_version "10"
  @mxid_regex ~r/^@[a-z0-9._=\/-]+:[a-z0-9][a-z0-9.\-]*$/i

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

  @doc """
  Invites a user to a room for `POST /_matrix/client/v3/rooms/{roomId}/invite`.
  """
  @spec invite(Account.t(), String.t(), map()) ::
          {:ok, map()}
          | {:error, map()}
          | {:error, :not_found | :forbidden | :already_joined}
  def invite(%Account{} = inviter, room_id, params) when is_binary(room_id) and is_map(params) do
    with {:ok, room} <- fetch_room(room_id),
         {:ok, invitee_mxid} <- parse_user_id(params),
         :ok <- validate_local_mxid(invitee_mxid),
         {:ok, invitee} <- fetch_local_account(invitee_mxid) do
      case Rooms.invite_user(room, inviter, invitee) do
        {:ok, _membership} -> {:ok, %{}}
        {:error, :forbidden} -> {:error, :forbidden}
        {:error, :already_joined} -> {:error, :already_joined}
        {:error, %Ecto.Changeset{}} -> {:error, Errors.invalid_param("Unable to invite user")}
      end
    end
  end

  @doc """
  Joins a room for `POST /_matrix/client/v3/join/{roomId}`.
  """
  @spec join(Account.t(), String.t()) ::
          {:ok, map()} | {:error, map()} | {:error, :not_found | :forbidden}
  def join(%Account{} = account, room_id) when is_binary(room_id) do
    room_id = URI.decode(room_id)

    with {:ok, room} <- fetch_room(room_id) do
      case Rooms.join_room(room, account) do
        {:ok, _membership} -> {:ok, %{"room_id" => room.room_id}}
        {:error, :forbidden} -> {:error, :forbidden}
        {:error, %Ecto.Changeset{}} -> {:error, Errors.invalid_param("Unable to join room")}
      end
    end
  end

  defp fetch_room(room_id) do
    case Rooms.fetch_room_by_room_id(room_id) do
      {:ok, room} -> {:ok, room}
      {:error, :not_found} -> {:error, :not_found}
    end
  end

  defp parse_user_id(%{"user_id" => user_id}) when is_binary(user_id) and user_id != "" do
    if Regex.match?(@mxid_regex, user_id) do
      {:ok, user_id}
    else
      {:error, Errors.invalid_param("Invalid user_id: #{inspect(user_id)}")}
    end
  end

  defp parse_user_id(_params) do
    {:error, Errors.invalid_param("Missing user_id")}
  end

  defp validate_local_mxid(mxid) do
    server_name = WellKnown.server_name()

    case String.split(mxid, ":", parts: 2) do
      [_localpart, ^server_name] -> :ok
      _ -> {:error, Errors.invalid_param("User is not on this homeserver")}
    end
  end

  defp fetch_local_account(mxid) do
    case Accounts.fetch_account_by_mxid(mxid) do
      {:ok, account} -> {:ok, account}
      {:error, :not_found} -> {:error, Errors.invalid_param("Unknown user")}
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
