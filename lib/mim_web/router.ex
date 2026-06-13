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

  pipeline :matrix_well_known do
    plug :accepts, ["json"]
    plug MimWeb.Plugs.MatrixCors
  end

  scope "/", MimWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/", MimWeb do
    pipe_through :matrix_well_known

    get "/.well-known/matrix/client", WellKnownController, :client
    options "/.well-known/matrix/client", WellKnownController, :client_options
    get "/.well-known/matrix/server", WellKnownController, :server
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
