defmodule Mim.Account do
  @moduledoc """
  Builds account-related Matrix client API responses.
  """

  alias Mim.Accounts.Account

  @doc """
  Returns the whoami response for `GET /_matrix/client/v3/account/whoami`.
  """
  @spec whoami(Account.t()) :: map()
  def whoami(%Account{mxid: mxid}) do
    %{"user_id" => mxid}
  end
end
