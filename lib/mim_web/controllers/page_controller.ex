defmodule MimWeb.PageController do
  use MimWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
