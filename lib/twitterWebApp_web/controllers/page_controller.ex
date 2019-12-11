defmodule TwitterWebAppWeb.PageController do
  use TwitterWebAppWeb, :controller

  def index(conn, _params) do
    IO.puts("HEreeee #{inspect Application.get_env(TwitterWebApp, :serverPid)}")
    render(conn, "index.html")
  end

  def signUp(conn, _params) do
    render(conn, "signUp.html")
  end

  def register(conn, params) do
    {:ok, username} = Map.fetch(params, "username")
    {:ok, password} = Map.fetch(params, "psw")
    {:ok, rePassword} = Map.fetch(params, "psw-repeat")
    if (rePassword != password) do
      attr_list = %{:hasError =>true, :reason=> "Username password did not match."}
      render(conn, "signUp.html", attr_list)
    else
      render(conn, "login.html")
    end
  end

  def login(conn, params) do
    {:ok, username} = Map.fetch(params, "username")
    {:ok, password} = Map.fetch(params, "pwd")
    {result, reason} = TwitterUtil.validateUser(username, password)
    IO.inspect({result, reason})
    if result==:ok do
      render(conn, "home.html")
    else
      attr_list = %{:hasError =>true, :reason=> reason}
      render(conn, "index.html", attr_list)
    end
  end
end
