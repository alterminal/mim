defmodule Mim.OpenId do
  @moduledoc """
  Matrix OpenID token issuance for `POST /_matrix/client/v1/user/{userId}/openid/request_token`.
  """

  alias Mim.OpenId.Token
  alias Mim.Repo
  alias Mim.WellKnown

  @default_ttl_seconds 3600
  @mxid_regex ~r/^@[a-z0-9._=\/-]+:[a-z0-9][a-z0-9.\-]*$/i

  @doc """
  Issues an OpenID token for the authenticated user.

  The `requested_mxid` must match the authenticated user's Matrix ID.
  """
  @spec request_token(String.t(), String.t()) :: {:ok, map()} | {:error, atom() | map()}
  def request_token(authenticated_mxid, requested_mxid) do
    cond do
      not valid_mxid?(requested_mxid) ->
        {:error, invalid_user_id()}

      authenticated_mxid != requested_mxid ->
        {:error, :forbidden}

      true ->
        issue_token(requested_mxid)
    end
  end

  @doc """
  Returns the configured OpenID token lifetime in seconds.
  """
  @spec token_ttl_seconds() :: pos_integer()
  def token_ttl_seconds do
    Application.get_env(:mim, :openid, [])
    |> Keyword.get(:token_ttl_seconds, @default_ttl_seconds)
  end

  defp issue_token(mxid) do
    expires_at = DateTime.add(DateTime.utc_now(:second), token_ttl_seconds(), :second)
    token = generate_token()

    %Token{}
    |> Token.changeset(%{
      token: token,
      mxid: mxid,
      expires_at: expires_at
    })
    |> Repo.insert()
    |> case do
      {:ok, _token} ->
        {:ok,
         %{
           "access_token" => token,
           "token_type" => "Bearer",
           "matrix_server_name" => WellKnown.server_name(),
           "expires_in" => token_ttl_seconds()
         }}

      {:error, _changeset} ->
        {:error, :internal_error}
    end
  end

  defp valid_mxid?(mxid), do: Regex.match?(@mxid_regex, mxid)

  defp invalid_user_id do
    %{
      "errcode" => "M_INVALID_PARAM",
      "error" => "User ID is invalid"
    }
  end

  defp generate_token do
    32 |> :crypto.strong_rand_bytes() |> Base.url_encode64(padding: false)
  end
end
