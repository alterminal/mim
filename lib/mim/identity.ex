defmodule Mim.Identity do
  @moduledoc """
  Configuration and helpers for the Matrix identity service API.
  """

  @default_algorithms ["sha256", "none"]

  @doc """
  Returns the hashing algorithms advertised by this identity server.
  """
  @spec algorithms() :: [String.t()]
  def algorithms do
    config(:algorithms) || @default_algorithms
  end

  @doc """
  Returns the lookup pepper clients must use when hashing identifiers.
  """
  @spec lookup_pepper() :: String.t()
  def lookup_pepper do
    config!(:lookup_pepper)
  end

  defp config(key), do: Application.get_env(:mim, :identity, []) |> Keyword.get(key)

  defp config!(key) do
    case config(key) do
      nil ->
        raise ArgumentError,
              "missing :mim, :identity, :#{key} configuration. " <>
                "Set MIM_IDENTITY_LOOKUP_PEPPER in production."

      value ->
        value
    end
  end
end
