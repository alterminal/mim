defmodule Mim.Matrix.Errors do
  @moduledoc """
  Standard Matrix client-server API error payloads.
  """

  @spec missing_token() :: map()
  def missing_token do
    %{"errcode" => "M_MISSING_TOKEN", "error" => "Missing access token"}
  end

  @spec unknown_token() :: map()
  def unknown_token do
    %{"errcode" => "M_UNKNOWN_TOKEN", "error" => "Unknown access token"}
  end

  @spec forbidden(String.t()) :: map()
  def forbidden(message \\ "You are not allowed to request tokens for this user") do
    %{"errcode" => "M_FORBIDDEN", "error" => message}
  end

  @spec invalid_param(String.t()) :: map()
  def invalid_param(message) do
    %{"errcode" => "M_INVALID_PARAM", "error" => message}
  end

  @spec not_found(String.t()) :: map()
  def not_found(message \\ "Not found") do
    %{"errcode" => "M_NOT_FOUND", "error" => message}
  end

  @spec unsupported_room_version(String.t()) :: map()
  def unsupported_room_version(version) do
    %{
      "errcode" => "M_UNSUPPORTED_ROOM_VERSION",
      "error" => "This server does not support that room version",
      "room_version" => version
    }
  end
end
