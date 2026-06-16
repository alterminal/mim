defmodule MimWeb.RoomController do
  use MimWeb, :controller

  alias Mim.Matrix.Errors
  alias Mim.Room

  def create(conn, params) do
    conn = put_resp_content_type(conn, "application/json")

    case Room.create(conn.assigns.current_account, params) do
      {:ok, response} ->
        json(conn, response)

      {:error, :unsupported_room_version, version} ->
        conn
        |> put_status(:bad_request)
        |> json(Errors.unsupported_room_version(version))

      {:error, %{"errcode" => _} = error} ->
        conn
        |> put_status(:bad_request)
        |> json(error)

      {:error, %Ecto.Changeset{}} ->
        conn
        |> put_status(:bad_request)
        |> json(Errors.invalid_param("Unable to create room"))
    end
  end

  def invite(conn, %{"room_id" => room_id} = params) do
    conn = put_resp_content_type(conn, "application/json")

    case Room.invite(conn.assigns.current_account, URI.decode(room_id), params) do
      {:ok, response} ->
        json(conn, response)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(Errors.not_found("Room not found"))

      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(Errors.forbidden("You are not allowed to invite users to this room"))

      {:error, :already_joined} ->
        conn
        |> put_status(:forbidden)
        |> json(Errors.forbidden("User is already in the room"))

      {:error, %{"errcode" => _} = error} ->
        conn
        |> put_status(:bad_request)
        |> json(error)
    end
  end

  def join(conn, %{"room_id" => room_id}) do
    conn = put_resp_content_type(conn, "application/json")

    case Room.join(conn.assigns.current_account, room_id) do
      {:ok, response} ->
        json(conn, response)

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(Errors.not_found("Room not found"))

      {:error, :forbidden} ->
        conn
        |> put_status(:forbidden)
        |> json(Errors.forbidden("You are not allowed to join this room"))

      {:error, %{"errcode" => _} = error} ->
        conn
        |> put_status(:bad_request)
        |> json(error)
    end
  end

  def create_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end

  def invite_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end

  def join_options(conn, _params) do
    send_resp(conn, :no_content, "")
  end
end
