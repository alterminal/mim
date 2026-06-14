defmodule Mim.Oidc.HTTP do
  @moduledoc false

  @spec get(String.t(), keyword()) :: {:ok, Req.Response.t()} | {:error, Exception.t()}
  def get(url, opts \\ []), do: Req.get(url, opts)

  @spec post(String.t(), keyword()) :: {:ok, Req.Response.t()} | {:error, Exception.t()}
  def post(url, opts \\ []), do: Req.post(url, opts)
end
