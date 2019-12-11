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
end