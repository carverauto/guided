defmodule GuidedWeb.Router do
  use GuidedWeb, :router

  import GuidedWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {GuidedWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", GuidedWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/knowledge", KnowledgeLive, :index
    live "/knowledge/:id", KnowledgeLive, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", GuidedWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:guided, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: GuidedWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", GuidedWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", GuidedWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  ## Admin routes - Knowledge Graph Management

  scope "/admin", GuidedWeb.Admin do
    pipe_through [:browser, :require_authenticated_user]

    live "/", DashboardLive, :index
    live "/technologies", TechnologyLive.Index, :index
    live "/technologies/new", TechnologyLive.Index, :new
    live "/technologies/:id/edit", TechnologyLive.Index, :edit

    live "/vulnerabilities", VulnerabilityLive.Index, :index
    live "/vulnerabilities/new", VulnerabilityLive.Index, :new
    live "/vulnerabilities/:id/edit", VulnerabilityLive.Index, :edit

    live "/security_controls", SecurityControlLive.Index, :index
    live "/security_controls/new", SecurityControlLive.Index, :new
    live "/security_controls/:id/edit", SecurityControlLive.Index, :edit

    live "/best_practices", BestPracticeLive.Index, :index
    live "/best_practices/new", BestPracticeLive.Index, :new
    live "/best_practices/:id/edit", BestPracticeLive.Index, :edit

    live "/relationships", RelationshipLive.Index, :index
  end

  scope "/", GuidedWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
