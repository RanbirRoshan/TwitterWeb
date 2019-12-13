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

  def startSimulation(conn, params) do
    {:ok, userCount} = Map.fetch(params, "UserCount")
    {:ok, tweetCount} = Map.fetch(params, "TweetCount")

    {tweetCount, _} = Integer.parse(tweetCount)
    {userCount, _}  = Integer.parse(userCount)
    simulator_pid = Application.get_env(TwitterWebApp, :simulatorPid)
    if simulator_pid == nil do
      {:ok, server_id} = GenServer.start(Simulator, {userCount, tweetCount})
      GenServer.cast(server_id, {:start})
      Application.put_env(TwitterWebApp, :simulatorPid, server_id)
      redirect(conn, to: "/")
    else
      if (GenServer.call(simulator_pid, {:isDone}, 999999999) == false)do
        redirect(conn, to: "/")
      else
        Application.put_env(TwitterWebApp, :simulatorPid, nil)
        redirect(conn, to: "/")
      end
    end
  end

  def isSimulationActive(conn, _params) do
    simulator_pid = Application.get_env(TwitterWebApp, :simulatorPid)

    if simulator_pid == nil do
      text(conn, "false")
    else
      if (GenServer.call(simulator_pid, {:isDone}, 999999999) == false)do
        text(conn, "true")
      else
        Application.put_env(TwitterWebApp, :simulatorPid, nil)
        text(conn, "false")
      end
    end
  end

  def index(conn, _params) do
    render(conn, "simulation.html")
#    if !is_nil(Plug.Conn.get_session(conn, "isLoggedIn")) && Plug.Conn.get_session(conn, "isLoggedIn") do
#
#      redirect(conn, to: "/home")
#    else
#      render(conn, "index.html")
#    end
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
      #yinspect({ret, reason})
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
      if ret == :ok do
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
