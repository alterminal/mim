defmodule Mim.Identity.HashDetails do
  @moduledoc """
  Builds the hash details response for `GET /_matrix/identity/v2/hash_details`.
  """

  alias Mim.Identity

  @doc """
  Returns the hash details document.
  """
  @spec document() :: map()
  def document do
    %{
      "algorithms" => Identity.algorithms(),
      "lookup_pepper" => Identity.lookup_pepper()
    }
  end
end
