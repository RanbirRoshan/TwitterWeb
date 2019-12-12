defmodule TwitterWebAppWeb.PageController do
  use TwitterWebAppWeb, :controller

  def logout(conn, _parms) do
    conn=
    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) && Plug.Conn.get_session(conn, "isLoggedIn") do
      conn = Plug.Conn.delete_session(conn, :isLoggedIn)
      conn = Plug.Conn.delete_session(conn, :username)
      conn = Plug.Conn.delete_session(conn, :password)
    end
    render(conn, "index.html")
  end

  def index(conn, _params) do
    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) && Plug.Conn.get_session(conn, "isLoggedIn") do

      redirect(conn, to: "/home")
    else
      render(conn, "index.html")
    end
  end


  def signUp(conn, _params) do
    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) && Plug.Conn.get_session(conn, "isLoggedIn") do
      redirect(conn, to: "/home")
    else
      render(conn, "signUp.html")
    end
  end


  def register(conn, params) do
    {:ok, username} = Map.fetch(params, "username")
    {:ok, password} = Map.fetch(params, "psw")
    {:ok, rePassword} = Map.fetch(params, "psw-repeat")
    if (rePassword != password) do
      attr_list = %{:hasError =>true, :reason=> "Username password did not match."}
      render(conn, "signUp.html", attr_list)
    else
      {ret, reason} = TwitterUtil.registerUser(username, password)
      if ret==:ok do
        render(conn, "index.html")
      else
        attr_list = %{:hasError =>true, :reason=> "Username password did not match."}
        render(conn, "signUp.html", attr_list)
      end
    end
  end


  def postTweet(conn, params) do
    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) && Plug.Conn.get_session(conn, "isLoggedIn") do
      username = Plug.Conn.get_session(conn, "username")
      password = Plug.Conn.get_session(conn, "password")
      {:ok, tweet} = Map.fetch(params, "tweet")
      {ret, reason} = TwitterUtil.tweet(username, password, tweet)
      if ret==:ok do
        redirect(conn, to: "/home")
      else
        attr_list = %{:hasError =>true, :reason=> reason}
        render(conn, "home.html", attr_list)
      end
    else
      redirect(conn, to: "/")
    end
  end

  def subscribe(conn, params) do
    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) && Plug.Conn.get_session(conn, "isLoggedIn") do
      username = Plug.Conn.get_session(conn, "username")
      password = Plug.Conn.get_session(conn, "password")
      {:ok, tweet} = Map.fetch(params, "Follow")
      {ret, reason} = TwitterUtil.subscribeUser(username, password, tweet)
      #IO.inspect({ret, reason})
      #if ret==:ok do
        redirect(conn, to: "/FindUsers")
      #else
      #  attr_list = %{:hasError =>true, :reason=> reason}
      #  render(conn, "home.html", attr_list)
      #end
    else
      redirect(conn, to: "/")
    end
  end

  def getUserList(conn, params) do
    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) && true == Plug.Conn.get_session(conn, "isLoggedIn") do
      username = Plug.Conn.get_session(conn, "username")
      password = Plug.Conn.get_session(conn, "password")

      {ret, data} = TwitterUtil.getAllUsers(username, password)
      if ret == :ok do
        json(conn, data)
      else
        json(conn, data)
      end
    else
      json(conn, [])
    end
  end

  def findUsers(conn, params) do
    render(conn, "findUsers.html")
  end

  def getPosts(conn, params) do
    page =
    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) && true == Plug.Conn.get_session(conn, "isLoggedIn") do
      username = Plug.Conn.get_session(conn, "username")
      password = Plug.Conn.get_session(conn, "password")

      {ret, data} = TwitterUtil.getTweets(username, password)
      IO.inspect(data)
      if ret == :ok do
        IO.inspect(data)
        response =
          for {from, time, text}<-data do
            %{:from=>from, :time=>time, :tweetText=>text}
          end
        json(conn, response)
      else
        send_resp(conn, 200, data)
      end
    else
      json(conn, [])
    end
  end


  def home(conn, params) do
    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) do
      render(conn, "home.html")
    else
      render(conn, "index.html")
    end
  end


  def login(conn, params) do
    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) && Plug.Conn.get_session(conn, "isLoggedIn") do
      redirect(conn, to: "/home")
    else
      {:ok, username} = Map.fetch(params, "username")
      {:ok, password} = Map.fetch(params, "pwd")
      {result, reason} = TwitterUtil.validateUser(username, password)
      if result==:ok do
        conn = Plug.Conn.put_session(conn, :username, username)
        conn = Plug.Conn.put_session(conn, :password, password)
        conn = Plug.Conn.put_session(conn, :isLoggedIn, true)
        render(conn, "home.html")
      else
        attr_list = %{:hasError =>true, :reason=> reason}
        render(conn, "index.html", attr_list)
      end
    end
  end
end
