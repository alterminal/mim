defmodule Mim.OpenIdTest do
  use Mim.DataCase, async: true

  alias Mim.OpenId
  alias Mim.OpenId.Token
  alias Mim.Repo

  test "request_token/2 returns an OpenID token for the authenticated user" do
    mxid = "@alice:localhost"

    assert {:ok, response} = OpenId.request_token(mxid, mxid)

    assert %{
             "access_token" => token,
             "token_type" => "Bearer",
             "matrix_server_name" => "localhost",
             "expires_in" => 3600
           } = response

    assert %Token{token: ^token, mxid: ^mxid} = Repo.get_by(Token, token: token)
  end

  test "request_token/2 rejects requests for a different user" do
    assert {:error, :forbidden} =
             OpenId.request_token("@alice:localhost", "@bob:localhost")
  end

  test "request_token/2 rejects invalid user IDs" do
    assert {:error, %{"errcode" => "M_INVALID_PARAM"}} =
             OpenId.request_token("@alice:localhost", "not-a-mxid")
  end
end
