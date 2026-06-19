defmodule Mim.Identity.Errors do
  @moduledoc """
  Standard Matrix identity service API error payloads.
  """

  @spec unauthorized(String.t()) :: map()
  def unauthorized(message \\ "Unauthorized") do
    %{"errcode" => "M_UNAUTHORIZED", "error" => message}
  end
end
