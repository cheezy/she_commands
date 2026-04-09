defmodule SheCommandsWeb.Router do
  use SheCommandsWeb, :router

  import SheCommandsWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SheCommandsWeb.Layouts, :root}
    plug :protect_from_forgery

    plug :put_secure_browser_headers, %{
      "content-security-policy" =>
        "default-src 'self'; script-src 'self' 'unsafe-inline'; img-src 'self' data:; style-src 'self' 'unsafe-inline'"
    }

    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_coach_or_admin do
    plug SheCommandsWeb.Plugs.Authorization, [:coach, :admin]
  end

  pipeline :require_admin do
    plug SheCommandsWeb.Plugs.Authorization, :admin
  end

  ## Public routes - accessible to all users

  scope "/", SheCommandsWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/brand", PageController, :brand
    get "/goal-execution", PageController, :goal_execution
    get "/experiences", PageController, :experiences
    get "/connect", PageController, :connect
    get "/the-journal", PageController, :the_journal
  end

  ## Authentication routes - guest-only (redirect if already logged in)

  scope "/", SheCommandsWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  ## Authentication routes - accessible to all

  scope "/", SheCommandsWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end

  ## Protected routes - require authentication

  scope "/", SheCommandsWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated, on_mount: [{SheCommandsWeb.UserAuth, :ensure_authenticated}] do
      live "/intake", IntakeLive.Index, :index
    end

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/email", UserSettingsController, :edit_email
    get "/users/settings/password", UserSettingsController, :edit_password
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
    delete "/users/settings", UserSettingsController, :delete_account
  end

  ## Coach routes - require coach or admin role

  scope "/coach", SheCommandsWeb do
    pipe_through [:browser, :require_authenticated_user, :require_coach_or_admin]
  end

  ## Admin routes - require admin role

  scope "/admin", SheCommandsWeb do
    pipe_through [:browser, :require_authenticated_user, :require_admin]
  end

  ## Development routes

  if Application.compile_env(:she_commands, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SheCommandsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
