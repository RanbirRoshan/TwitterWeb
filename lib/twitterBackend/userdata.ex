defmodule UserInfo do
  defstruct userId: "", password: "", tweets: [], subscribedTo: [], userDeleted: false, userMention: [], userPid: nil, subscribedBy: []
end

defmodule UserDataServer do
  use GenServer
  require Logger

  def hello do
    :world
  end

  @impl true
  def init(init_arg) do
    user_table = :ets.new(:user_lookup, [:set, :protected])
    tweet_table = :ets.new(:tweet_lookup, [:set, :protected])
    hash_table = :ets.new(:hash_lookup, [:set, :protected])
    state = %{:userTable => user_table, :tweetTable => tweet_table, :hashTable => hash_table, :tweetCount => 0}
    {:ok, state}
  end

  @impl true
  def handle_call({:CreateUser, userData}, _from, state) do

    is_new = :ets.insert_new(state.userTable, {userData.userId, userData})

    if is_new do
      {:reply, {:ok, "Success"}, state}
    else
      {:reply, {:bad, "UserId already in use"}, state}
    end
  end

  @impl true
  def handle_call({:DeleteUser, userId}, _from, state) do
    #IO.inspect(userId)
    data = :ets.lookup(state.userTable, userId)
    if Enum.count(data) > 0 do
      :ets.delete(state.userTable, userId)
      {:reply, {:ok, "Success"}, state}
    else
      {:reply, {:bad, "Invalid User ID"}, state}
    end
  end


  @impl true
  def handle_call({:AddLogoutDetail, userId}, _from, state) do
    data = :ets.lookup(state.userTable, userId)
    if Enum.count(data) > 0 do
      {_id, user} = Enum.at(data, 0)
      updateUserInfo = %UserInfo{userId: user.userId, password: user.password, tweets: user.tweets, subscribedTo: user.subscribedTo, userDeleted: user.userDeleted, userMention: user.userMention, userPid: nil, subscribedBy: user.subscribedBy}
      :ets.insert(state.userTable, {userId, updateUserInfo})
      {:reply, {:ok, "success"}, state}
    else
      {:reply, {:bad, "Invalid User ID"}, state}
    end
  end

  @impl true
  def handle_call({:AddLoginDetail, userId, userpid}, _from, state) do
    data = :ets.lookup(state.userTable, userId)
    if Enum.count(data) > 0 do
      {_id, user} = Enum.at(data, 0)
      updateUserInfo = %UserInfo{userId: user.userId, password: user.password, tweets: user.tweets, subscribedTo: user.subscribedTo, userDeleted: user.userDeleted, userMention: user.userMention, userPid: userpid, subscribedBy: user.subscribedBy}
      :ets.insert(state.userTable, {userId, updateUserInfo})
      {:reply, {:ok, "Success"}, state}
    else
      {:reply, {:bad, "Invalid User ID"}, state}
    end
  end

  @impl true
  def handle_call({:GetUserById, userId}, _from, state) do
    data = :ets.lookup(state.userTable, userId)
    if Enum.count(data) > 0 do
      {_id, user} = Enum.at(data, 0)
      {:reply, {:ok, user}, state}
    else
      {:reply, {:bad, "Invalid User ID"}, state}
    end
  end

  @impl true
  def handle_call({:Tweet, tweet}, _from, state) do
    tweet_id = state.tweetCount
    state = %{state | :tweetCount=>tweet_id+1}
    :ets.insert_new(state.tweetTable, {tweet_id,tweet})
    {:reply, {:ok, tweet_id}, state}
  end

  @impl true
  def handle_call({:GetTweet, tweet_id}, _from, state) do
    [{tweet_id, tweet}] = :ets.lookup(state.tweetTable, tweet_id)
    {:reply, {:ok, tweet}, state}
  end

  @impl true
  def handle_call({:UpdateUser, user}, _from, state) do
    data = :ets.lookup(state.userTable, user.userId)
    if Enum.count(data) > 0 do
      :ets.insert(state.userTable, {user.userId, user})
      {:reply, {:ok, "Success"}, state}
    else
      {:reply, {:bad, "Invalid User ID"}, state}
    end
  end

  @impl true
  def handle_call({:AddHashTagData, hash, tweet_server, tweet_id}, _from, state) do
    data = :ets.lookup(state.hashTable, hash)
    if Enum.count(data) > 0 do
      {hash, tweetList} = Enum.at(data, 0)
      :ets.insert(state.hashTable, {hash, tweetList ++ [{tweet_server, tweet_id}]})
    else
      :ets.insert_new(state.hashTable, {hash, [{tweet_server, tweet_id}]})
    end
    {:reply, {:ok, "Success"}, state}
  end

  @impl true
  def handle_call({:GetHashTagData, hashtag}, _from, state) do
    data = :ets.lookup(state.hashTable, hashtag)
    if Enum.count(data) > 0 do
      {hash, tweetList} = Enum.at(data, 0)
      {:reply, {:ok, tweetList}, state}
    else
      {:reply, {:ok, []}, state}
    end
  end

  @impl true
  def handle_call({:AddUserMention, username, tweet_server, tweet_id}, _from, state) do
    data = :ets.lookup(state.userTable, username)
    if Enum.count(data) > 0 do
      {_name, user} = Enum.at(data, 0)
      if user.userDeleted == false do
        updateUserInfo = %UserInfo{userId: user.userId, password: user.password, tweets: user.tweets, subscribedTo: user.subscribedTo, userDeleted: user.userDeleted, userMention: user.userMention++[{tweet_server, tweet_id}], userPid: user.userPid, subscribedBy: user.subscribedBy}
        :ets.insert(state.userTable, {username, updateUserInfo})
      end
    end
    {:reply, {:ok, "Success"}, state}
  end
end