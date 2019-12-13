defmodule TwitterUtil do

  def sendInfoToServer(server_id, data, print) do
    {ret, ret_data} = GenServer.call(server_id, data)
    if print == true do
      #Logger.info("#{inspect {ret, ret_data, data}}")
    end
    if (ret == :redirect) do
      sendInfoToServer(ret_data, data, print)
    else
      {ret, ret_data}
    end
  end

  def validateUser(username, password) do
    sendInfoToServer(Application.get_env(TwitterWebApp, :serverPid), {:Login, username, password}, false)
  end

  def registerUser(username, password) do
    sendInfoToServer(Application.get_env(TwitterWebApp, :serverPid), {:RegisterUser, username, password}, false)
  end

  def tweet(username, password, tweet) do
    sendInfoToServer(Application.get_env(TwitterWebApp, :serverPid), {:PostTweet, username, password, tweet}, false)
  end

  def getTweets(username, password) do
    sendInfoToServer(Application.get_env(TwitterWebApp, :serverPid), {:GetSubscribedTweet, username, password}, false)
  end

  def subscribeUser(username, password, followUser) do
    sendInfoToServer(Application.get_env(TwitterWebApp, :serverPid), {:SubscribeUser, username, password, followUser}, false)
  end

  def getAllUsers(username, password) do
    sendInfoToServer(Application.get_env(TwitterWebApp, :serverPid), {:GetUserList, username, password}, false)
  end

  def getTweetbyTag(tag) do
    if (Application.get_env(TwitterWebApp, :simulatorPid)!=nil) do
      ret = GenServer.call(Application.get_env(TwitterWebApp, :simulatorPid), {:getServerPid})
      sendInfoToServer(ret, {:GetTweetsByHashTag, tag}, false)
    else
      {:ok ,["No Active Simulation."]}
    end
  end

  def getUserFeed(name) do
    if (Application.get_env(TwitterWebApp, :simulatorPid)!=nil) do
      ret = GenServer.call(Application.get_env(TwitterWebApp, :simulatorPid), {:getServerPid})
      pwd = GenServer.call(Application.get_env(TwitterWebApp, :simulatorPid), {:getUserPwd, name})
      IO.inspect(pwd)
      sendInfoToServer(ret, {:GetSubscribedTweet, name, pwd}, false)
    else
      {:ok ,["No Active Simulation."]}
    end
  end

  def getUserMentions(name) do
    if (Application.get_env(TwitterWebApp, :simulatorPid)!=nil) do
      ret = GenServer.call(Application.get_env(TwitterWebApp, :simulatorPid), {:getServerPid})
      pwd = GenServer.call(Application.get_env(TwitterWebApp, :simulatorPid), {:getUserPwd, name})
      IO.inspect(pwd)
      sendInfoToServer(ret, {:GetMyMention, name, pwd}, false)
    else
      {:ok ,["No Active Simulation."]}
    end
  end
end