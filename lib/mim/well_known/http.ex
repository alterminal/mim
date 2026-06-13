defmodule Mim.WellKnown.HTTP do
  @moduledoc false

  @spec get(String.t(), keyword()) :: {:ok, Req.Response.t()} | {:error, Exception.t()}
  def get(url, opts \\ []) do
    Req.get(url, opts)
  end
end
