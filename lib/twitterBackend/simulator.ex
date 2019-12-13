defmodule Simulator do
  use GenServer
  require Logger

  # Dosassignment2]
  @alphabets "abcdefghijklmnopqrstuvwxyz"
  @follow_count_percent 0.30
  #@tweet_count 500
  @hash_tag_list_size 15 #100
  @max_hash_count_per_msg 10
  #@number_of_users  25 #100
  @max_wait_time_milli_sec 4

  @impl true
  def init(init_arg) do
    {num_user, num_tweet} = init_arg
    state = %{:num_start_end_pending => num_user, :numUser=>num_user, :numMsg=>num_tweet}
    {:ok, state}
  end

  def getRandomString(len, ans) do
    if len > 0 do
      random = :rand.uniform(26) - 1
      ans = ans <> String.at(@alphabets, random)
      getRandomString(len-1, ans)
    else
      ans
    end
  end

  def generateHashTagList(count, list) do
    if count>0 do
      hash_len = :rand.uniform(4)
      hash = "#" <> getRandomString(5+hash_len, "")
      if (Enum.find_index(list,  fn(hash_data) -> hash_data == hash end)) == nil do
        generateHashTagList(count-1, list ++ [hash])
      else
        generateHashTagList(count, list)
      end
    else
      list
    end
  end

  def createRandomUserIdPassowrd(count, list) do
    if (count == 0) do
      list
    else
      uniquelen = 4 + :rand.uniform(10)
      username_new = getRandomString(uniquelen, "") #<> "@" <> getRandomString(4, "") <> ".com"
      passwordLen = 8 + :rand.uniform(4)
      password = getRandomString(passwordLen, "")
      if (Enum.find_index(list,  fn({username, _password}) -> username == username_new end)) == nil do
        createRandomUserIdPassowrd(count-1, list ++ [{username_new, password}])
      else
        createRandomUserIdPassowrd(count, list)
      end
    end
  end

  def updateEmptyUserMentionCount(user, server_id) do
    data =
      for {name, _}<-user do
        %{"username"=>name, "count"=>0}
      end
    Application.put_env(TwitterWebApp, :userData, data)
  end

  def updateUserMentionCount(users, server_id,server_pid) do
    if (GenServer.call(server_pid, {:isDone})) do
    else
      counts =
        for {name, password}<-users do
          {res, data} = GenServer.call(server_id, {:GetMyMention, name, password})
          {res, data} = GenServer.call(data, {:GetMyMention, name, password})
          if res == :ok do
            %{"username"=>name, "count"=>Enum.count(data)}
          else
            %{"username"=>name, "count"=>0}
          end
        end
      TwitterWebAppWeb.Endpoint.broadcast!("twitter:tagCount", "userCount", %{"data"=>counts})
      Process.sleep(500)
      updateUserMentionCount(users, server_id, server_pid)
    end
  end

  def updateEmptyTagCount(tags, server_id) do
    data =
      for tag<-tags do
        %{"Tag"=>tag, "count"=>0}
      end
    Application.put_env(TwitterWebApp, :tagData, data)
  end

  def updateTagCount(tags, server_id, server_pid) do
   # {:ok, complete} = GenServer.call(server_pid, {:isDone})
    if (GenServer.call(server_pid, {:isDone})) do
    else
      counts =
      for tag<-tags do
        {res, data} = GenServer.call(server_id, {:GetTweetsByHashTag, tag})
        {res, data} = GenServer.call(data, {:GetTweetsByHashTag, tag})
        if res == :ok do
          %{"Tag"=>tag, "count"=>Enum.count(data)}
        else
          %{"Tag"=>tag, "count"=>0}
        end
      end
      TwitterWebAppWeb.Endpoint.broadcast!("twitter:tagCount", "shout", %{"data"=>counts})
      Process.sleep(500)
      updateTagCount(tags, server_id, server_pid)
    end
  end

  def createClientAccount(count, server_id, list_user, client_list, hash_tag_list, numMsg) do
    if (count > 0) do
      follow_count = Enum.count(list_user) * @follow_count_percent
      data = {count-1, list_user, follow_count, numMsg, hash_tag_list, server_id, self(), @max_hash_count_per_msg}
      {:ok, client_pid} = GenServer.start(Client, data)
      GenServer.call(client_pid, {:createAccount})
      createClientAccount(count-1, server_id, list_user, client_list ++ [client_pid], hash_tag_list, numMsg)
    else
      client_list
    end
  end

  def startClient(client_list, pos) do
    if pos < Enum.count(client_list) do
      GenServer.cast(Enum.at(client_list,pos), {:start, @max_wait_time_milli_sec})
      startClient(client_list, pos+1)
    end
  end

  @impl true
  def handle_call({:InformStartCompletion}, _from, state) do
    state = %{state| :num_start_end_pending => state.num_start_end_pending-1}
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:isDone}, _from, state) do
    if (state.num_start_end_pending > 0) do
      {:reply, false, state}
    else
      {:reply, true, state}
    end
  end

  @impl true
  def handle_cast({:newTweet, tweet}, state) do
   # IO.inspect(tweet)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:start}, state) do
    userid_pwd_list = createRandomUserIdPassowrd(state.numUser, [])
    {:ok, server_id} = GenServer.start(Twitter, %{})
    hash_list   = generateHashTagList(@hash_tag_list_size, [])
    updateEmptyTagCount(hash_list, server_id)
    client_list = createClientAccount(state.numUser, server_id, userid_pwd_list, [], hash_list, state.numMsg)
    updateEmptyUserMentionCount(userid_pwd_list, server_id)
    startClient(client_list, 0)
    self = self()
    spawn fn() ->
      updateTagCount(hash_list, server_id, self)
    end
    spawn fn ->
      updateUserMentionCount(userid_pwd_list, server_id, self)
    end
    {:noreply, state}
  end
end