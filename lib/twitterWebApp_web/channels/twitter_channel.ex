defmodule TwitterWebAppWeb.TwitterChannel do
  use TwitterWebAppWeb, :channel

  def join("twitter:tagCount", payload, socket) do
    if authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("getUserInfo", payload, socket) do

    {:reply, {:ok, payload}, socket}
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  def handle_in("getTagInfo", payload, socket) do
    tag = Map.get(payload, "tag")
    {ret, data} = TwitterUtil.getTweetbyTag(tag)
    retdata =
      for {a,b,c}<-data do
        ["Sender:   "<>a<>"   Tweet:  "<>c]
      end
    push(socket, "getTagInfoData", %{val: retdata})
    {:noreply, socket}
  end
  def handle_in("getUserFeed", payload, socket) do
    name = Map.get(payload, "username")
    {ret, data} = TwitterUtil.getUserFeed(name)
    retdata =
      for {a,b,c}<-data do
        ["Sender:   "<>a<>"   Tweet:  "<>c]
      end
    push(socket, "getUserFeedData", %{val: retdata})
    {:noreply, socket}
  end
  def handle_in("getUserMentions", payload, socket) do
    name = Map.get(payload, "username")
    {ret, data} = TwitterUtil.getUserMentions(name)
    retdata =
      for {a,b,c}<-data do
        ["Sender:   "<>a<>"   Tweet:  "<>c]
      end
    push(socket, "getUserMentionsData", %{val: retdata})
    {:noreply, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (twitter:lobby).
  def handle_in("shout", payload, socket) do
    broadcast socket, "shout", payload
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
