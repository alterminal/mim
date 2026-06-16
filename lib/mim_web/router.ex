defmodule MimWeb.Router do
  use MimWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MimWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :matrix_api do
    plug :accepts, ["json"]
    plug MimWeb.Plugs.MatrixCors
  end

  pipeline :matrix_authenticated do
    plug MimWeb.Plugs.MatrixAuth
  end

  scope "/", MimWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/", MimWeb do
    pipe_through :matrix_api

    get "/.well-known/matrix/client", WellKnownController, :client
    options "/.well-known/matrix/client", WellKnownController, :client_options
    get "/.well-known/matrix/server", WellKnownController, :server
  end

  scope "/_matrix/client", MimWeb do
    pipe_through :matrix_api

    get "/versions", VersionsController, :index
    options "/versions", VersionsController, :index_options
    get "/v3/login", LoginController, :index
    post "/v3/login", LoginController, :create
    options "/v3/login", LoginController, :index_options
    get "/v3/auth_issuer", AuthIssuerController, :show
    options "/v3/auth_issuer", AuthIssuerController, :show_options
    get "/unstable/org.matrix.msc2965/auth_issuer", AuthIssuerController, :show
    options "/unstable/org.matrix.msc2965/auth_issuer", AuthIssuerController, :show_options

    options "/v1/user/:user_id/openid/request_token", OpenIdController, :request_token_options
    options "/v3/user/:user_id/openid/request_token", OpenIdController, :request_token_options
    options "/v3/account/whoami", AccountController, :whoami_options
    options "/v3/logout", LogoutController, :logout_options
    options "/v3/logout/all", LogoutController, :logout_all_options
    options "/v3/createRoom", RoomController, :create_options
    options "/v3/rooms/:room_id/invite", RoomController, :invite_options
    options "/v3/join/:room_id", RoomController, :join_options
  end

  scope "/_matrix/client", MimWeb do
    pipe_through [:matrix_api, :matrix_authenticated]

    post "/v3/createRoom", RoomController, :create
    post "/v3/rooms/:room_id/invite", RoomController, :invite
    post "/v3/join/:room_id", RoomController, :join
    get "/v3/account/whoami", AccountController, :whoami
    post "/v3/logout", LogoutController, :logout
    post "/v3/logout/all", LogoutController, :logout_all
    post "/v1/user/:user_id/openid/request_token", OpenIdController, :request_token
    post "/v3/user/:user_id/openid/request_token", OpenIdController, :request_token
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:mim, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MimWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
