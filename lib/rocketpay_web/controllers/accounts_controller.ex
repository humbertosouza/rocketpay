defmodule RocketpayWeb.AccountsController do
  use RocketpayWeb, :controller

  alias Rocketpay.Account

  action_fallback RocketpayWeb.FallbackController

  #%Account{} is a struct

  def deposit(conn, params) do
    with {:ok, %Account{} = account} <- Rocketpay.deposit(params) do

      conn
      |> put_status(:ok) # http 201
      |> render("update.json", account: account) #it will call a view. Create a view with same name of the controller
      end

  end

end
