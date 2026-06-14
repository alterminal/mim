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
end
