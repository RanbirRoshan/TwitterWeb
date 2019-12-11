defmodule TwitterWebAppWeb.Router do
  use TwitterWebAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", TwitterWebAppWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/SignUp", PageController, :signUp
    get "/login", PageController, :login
    get "/Register", PageController, :register
    get "/PostTweet", PageController, :postTweet
    get "/Logout", PageController, :logout
    get "/home", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", TwitterWebAppWeb do
  #   pipe_through :api
  # end
end
