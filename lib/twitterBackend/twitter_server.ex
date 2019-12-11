defmodule TwitterCoreServer do
  use GenServer
  require Logger


  def flatten([]), do: []
  def flatten([h|t]), do: flatten(h) ++ flatten(t)
  def flatten(h), do: [h]

  def stringTrim(data) do
    String.trim(data)
  end

  def postHashTagAndMentions(hashtag, mentions, state, tweet_server, tweet_id) do
    for tag<-hashtag do
      tag=convertToLower(tag)
      {server_pid, pos} = getDS(String.at(tag, 1), state)
      GenServer.call(server_pid, {:AddHashTagData, tag, tweet_server, tweet_id})
    end
    for mentionedUser<-mentions do
      mentionedUser=convertToLower(mentionedUser)
      {server_pid, pos} = getDS(String.slice(mentionedUser, 1..-1), state)
      GenServer.call(server_pid, {:AddUserMention, String.slice(mentionedUser, 1..-1), tweet_server, tweet_id})
    end
  end

  def getHashtagAndMentions(tweet) do
    hashregex = ~r/\#\w+/
    tags = List.flatten(Regex.scan(hashregex,tweet))
    hashregex = ~r/\@\w+/
    mentions = List.flatten(Regex.scan(hashregex,tweet))
    {Enum.uniq(tags),Enum.uniq(mentions)}
  end

  def validateUser(name, password, userObj) do
    if (name == userObj.userId && password == userObj.password && userObj.userDeleted == false) do
      true
    else
      false
    end
  end

  def convertToLower(data) do
    String.downcase(data)
  end

  def isStringNonEmpty(checkString) do
    checkString = String.trim(checkString)
    String.length(checkString) > 0
  end

  def validateNonEmptyString(data, label) do
    if isStringNonEmpty(data) do
      {:ok, "success"}
    else
      {:bad, label <> " cannot be empty"}
    end
  end

  def validateLoginData(name, password) do

    {valid, err_str} = validateNonEmptyString(name, "UserId")

    if valid == :ok do

      if String.contains?(name, " ") do
        {:bad, "User name cannot contain spaces."}
      else
        if valid == :ok do
          validateNonEmptyString(password, "Password")
        else
          {valid, err_str}
        end
      end
    else
      {valid, err_str}
    end
  end

  def getDS(word, state) do
    pos = hd(String.to_charlist(String.at(word, 0))) - hd('a')
    if (pos >=0 && pos<=25) do
      {Enum.at(state.userDataMap, pos), pos}
    else
      {Enum.at(state.userDataMap, 26), 26}
    end
  end

  @impl true
  def init(init_arg) do
    state = %{:userDataMap => init_arg}
    {:ok, state}
  end

  @impl true
  def handle_call({:RegisterUser, name, password}, _from, state) do

    name = stringTrim(convertToLower(name))

    {ret, reason} = validateLoginData(name, password)

    if ret == :ok do
      {server_pid, _} = getDS(name, state)
      newUser = %UserInfo{userId: name, password: password, tweets: [], subscribedTo: [], userDeleted: false, userMention: [], userPid: nil}
      {ret, reason} = GenServer.call(server_pid, {:CreateUser, newUser})
      {:reply, {ret, reason}, state}
    else
      {:reply, {ret, reason}, state}
    end
  end

  @impl true
  def handle_call({:Login, name, password}, from, state) do
    name = convertToLower(stringTrim(name))
    if isStringNonEmpty(name) do
      {server_pid, _} = getDS(name, state)
      {result, user} = GenServer.call(server_pid, {:GetUserById, name})
      if result == :ok && user.userDeleted == false do
        if (validateUser(name, password, user)) do
          {pid, _} = from
          {:reply, GenServer.call(server_pid ,{:AddLoginDetail, name, pid}), state}
        else
          {:reply, {:bad, "Invalid user id or password"}, state}
        end
      else
        {:reply, {:bad, "Invalid user id or password"}, state}
      end
    else
      {:reply, {:bad, "User Id cannot be empty"}, state}
    end
  end

  @impl true
  def handle_call({:Logout, name, password}, _from, state) do
    name = convertToLower(stringTrim(name))
    if isStringNonEmpty(name) do
      {server_pid, _} = getDS(name, state)
      {result, user} = GenServer.call(server_pid, {:GetUserById, name})
      if result == :ok && user.userDeleted == false do
        if (validateUser(name, password, user)) do
          {:reply, GenServer.call(server_pid, {:AddLoginDetail, name, nil}), state}
        else
          {:reply, {:bad, "Invalid user id or password"}, state}
        end
      else
        {:reply, {:bad, "Invalid user id or password"}, state}
      end
    else
      {:reply, {:bad, "User Id cannot be empty"}, state}
    end
  end

  @impl true
  def handle_call({:PostTweet, name, password, tweet}, _from, state) do
    tweet = stringTrim(tweet)
    if isStringNonEmpty(tweet) && isStringNonEmpty(name) do
      {server_pid, _} = getDS(name, state)
      {result, user} = GenServer.call(server_pid, {:GetUserById, name})
      if result == :ok && (validateUser(name, password, user)) do
        {tweet_server_pid, ds_pos} = getDS(convertToLower(tweet), state)
        {:ok, tweet_id} = GenServer.call(tweet_server_pid, {:Tweet, {name, DateTime.utc_now(), tweet}})
        {hashtag, mentions} = getHashtagAndMentions(tweet)
        postHashTagAndMentions(hashtag, mentions, state, ds_pos, tweet_id)
        for subs <- user.subscribedBy do
          {result, user} = GenServer.call(server_pid, {:GetUserById, name})
          if (user.userDeleted == false && user.userPid != nil) do
            GenServer.cast(user.userPid, {:Notification, "New tweet posted by " <> name <> " Tweet: " <> tweet})
          end
        end
        updateUserInfo = %UserInfo{userId: user.userId, password: user.password, tweets: user.tweets ++ [{ds_pos, tweet_id}], subscribedTo: user.subscribedTo, userPid: user.userPid, userDeleted: user.userDeleted, userMention: user.userMention, subscribedBy: user.subscribedBy}
        {:reply, GenServer.call(server_pid, {:UpdateUser, updateUserInfo}), state}
      else
        {:reply, {:bad, "Invalid user id or password"}, state}
      end
    else
      {:reply, {:bad, "Tweets cannot be empty"}, state}
    end
  end

  @impl true
  def handle_call({:DeleteUser, name, password}, _from, state) do
    name = convertToLower(stringTrim(name))
    if isStringNonEmpty(name) do
      {server_pid, _} = getDS(name, state)
      {result, user} = GenServer.call(server_pid, {:GetUserById, name})
      if result == :ok && user.userDeleted == false do
        if (validateUser(name, password, user)) do
          updateUserInfo = %UserInfo{userId: user.userId, password: user.password, tweets: user.tweets, subscribedTo: user.subscribedTo, userDeleted: true,userMention: user.userMention, userPid: nil, subscribedBy: user.subscribedBy}
          GenServer.call(server_pid, {:UpdateUser, updateUserInfo})
          {:reply, {:ok, "Success"}, state}
        else
          {:reply, {:bad, "Invalid user id or password"}, state}
        end
      else
        {:reply, {:bad, "Invalid user id or password"}, state}
      end
    else
      {:reply, {:bad, "User Id cannot be empty"}, state}
    end
  end

  @impl true
  def handle_call({:GetSubscribedTweet, name, password}, _from, state) do
    name = convertToLower(stringTrim(name))
    if isStringNonEmpty(name) do
      {server_pid, _} = getDS(name, state)
      {result, user} = GenServer.call(server_pid, {:GetUserById, name})
      if result == :ok && user.userDeleted == false do
        if (validateUser(name, password, user)) do

          tweets =
            for sub_user <- user.subscribedTo do
              {sub_server_pid, _} = getDS(sub_user, state)
              {sub_result, sub_user_obj} = GenServer.call(sub_server_pid, {:GetUserById, sub_user})
              if sub_user_obj.userDeleted == false do
                data =
                for {tweet_server, tweet_id} <- sub_user_obj.tweets do
                  {:ok, tweet} = GenServer.call(Enum.at(state.userDataMap, tweet_server), {:GetTweet, tweet_id})
                  tweet
                end
              else
                []
              end
          end
          ret_val = flatten(tweets) |> Enum.sort_by(&(elem(&1, 1)))
          {:reply, {:ok, ret_val}, state}
        else
          {:reply, {:bad, "Invalid user id or password"}, state}
        end
      else
        {:reply, {:bad, "Invalid user id or password"}, state}
      end
    else
      {:reply, {:bad, "User Id cannot be empty"}, state}
    end
  end

  @impl true
  def handle_call({:SubscribeUser, name, password, subscribeUserName}, _from, state) do
    subscribeUserName = convertToLower(stringTrim(subscribeUserName))
    if isStringNonEmpty(subscribeUserName) do
      {server_pid, _} = getDS(name, state)
      {result, user} = GenServer.call(server_pid, {:GetUserById, name})
      {sub_server_pid, _} = getDS(subscribeUserName, state)
      {sub_result, sub_user} = GenServer.call(sub_server_pid, {:GetUserById, subscribeUserName})
      if (user != sub_user) do
        if sub_result == :ok && sub_user.userDeleted == false do
          if result == :ok do
            if (validateUser(name, password, user)) do
              if !(Enum.member?(user.subscribedTo, subscribeUserName)) do
                updateUserInfo = %UserInfo{userId: sub_user.userId, password: sub_user.password, tweets: sub_user.tweets, subscribedTo: sub_user.subscribedTo, userMention: sub_user.userMention, userPid: sub_user.userPid, userDeleted: sub_user.userDeleted, subscribedBy: sub_user.subscribedBy++[name]}
                GenServer.call(sub_server_pid, {:UpdateUser, updateUserInfo})
                updateUserInfo = %UserInfo{userId: user.userId, password: user.password, tweets: user.tweets, subscribedTo: user.subscribedTo++[subscribeUserName], userMention: user.userMention, userPid: user.userPid, userDeleted: user.userDeleted, subscribedBy: user.subscribedBy}
                {:reply, GenServer.call(server_pid, {:UpdateUser, updateUserInfo}), state}
              else
                {:reply, {:bad, "Already Subscribed to user"}, state}
              end
            else
              {:reply, {:bad, "Invalid user id or password"}, state}
            end
          else
            {:reply, {:bad, "Invalid user id or password"}, state}
          end
        else
          {:reply, {:bad, "User being subscribed does not have an account"}, state}
        end
      else
        {:reply, {:bad, "Subscibing self is not allowed."}, state}
      end
    else
      {:reply, {:bad, "Subscibing user name cannot be empty"}, state}
    end
  end

  @impl true
  def handle_call({:GetTweetsByHashTag, hashTag}, _from, state) do
    hashTag = convertToLower(stringTrim(hashTag))
    if(isStringNonEmpty(hashTag)) do
      if (String.at(hashTag,0) == "#") do
        {server_id, pos} = getDS(String.at(hashTag, 1), state)
        {:ok, list} = GenServer.call(server_id, {:GetHashTagData, hashTag})
        tweets=
        for {ds_pos, tweet_id}<-list do
          {:ok, tweet} = GenServer.call(Enum.at(state.userDataMap, ds_pos), {:GetTweet, tweet_id})
          tweet
        end
        ret_val = flatten(tweets) |> Enum.sort_by(&(elem(&1, 1)))
        {:reply, {:ok, ret_val}, state}
      else
        {:reply, {:bad, "Hashtag must begin with hash."}, state}
      end
    else
      {:reply, {:bad, "Hashtag cannot be empty"}, state}
    end
  end

  @impl true
  def handle_call({:GetMyMention, name, password}, _from, state) do
    {server_pid, _} = getDS(name, state)
    {result, user} = GenServer.call(server_pid, {:GetUserById, name})
    if result == :ok && (validateUser(name, password, user)) do
      tweets=
        for {ds_pos, tweet_id}<-user.userMention do
          {:ok, tweet} = GenServer.call(Enum.at(state.userDataMap, ds_pos), {:GetTweet, tweet_id})
          tweet
        end
      ret_val = flatten(tweets) |> Enum.sort_by(&(elem(&1, 1)))
      {:reply, {:ok, ret_val}, state}
    else
      {:reply, {:bad, "Invalid user id or password"}, state}
    end
  end

  @impl true
  def handle_call({:ReTweet, name, password, old_tweet_data}, _from, state) do
    {_,_,tweet}=old_tweet_data
    tweet = stringTrim(tweet)
    if isStringNonEmpty(tweet) && isStringNonEmpty(name) do
      {server_pid, _} = getDS(name, state)
      {result, user} = GenServer.call(server_pid, {:GetUserById, name})
      if result == :ok && (validateUser(name, password, user)) do
        tweet = "Retweet: " <> tweet
        {tweet_server_pid, ds_pos} = getDS(convertToLower(tweet), state)
        {:ok, tweet_id} = GenServer.call(tweet_server_pid, {:Tweet, {name, DateTime.utc_now(), tweet}})
        {hashtag, mentions} = getHashtagAndMentions(tweet)
        postHashTagAndMentions(hashtag, mentions, state, ds_pos, tweet_id)
        for subs <- user.subscribedBy do
          {result, user} = GenServer.call(server_pid, {:GetUserById, name})
          if (user.userDeleted == false && user.userPid != nil) do
            GenServer.cast(user.userPid, {:Notification, "New tweet posted by " <> name <> " Tweet: " <> tweet})
          end
        end
        updateUserInfo = %UserInfo{userId: user.userId, password: user.password, tweets: user.tweets ++ [{ds_pos, tweet_id}], subscribedTo: user.subscribedTo, userPid: user.userPid, userDeleted: user.userDeleted, userMention: user.userMention, subscribedBy: user.subscribedBy}
        {:reply, GenServer.call(server_pid, {:UpdateUser, updateUserInfo}), state}
      else
        {:reply, {:bad, "Invalid user id or password"}, state}
      end
    else
      {:reply, {:bad, "Tweets cannot be empty"}, state}
    end
  end
end