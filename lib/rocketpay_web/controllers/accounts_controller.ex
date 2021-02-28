defmodule RocketpayWeb.AccountsController do
  use RocketpayWeb, :controller

  alias Rocketpay.Account

  alias Rocketpay.Accounts.Transaction.Response, as: TransactionResponse

  action_fallback RocketpayWeb.FallbackController

  #%Account{} is a struct

  def deposit(conn, params) do
    with {:ok, %Account{} = account} <- Rocketpay.deposit(params) do

      conn
      |> put_status(:ok) # http 201
      |> render("update.json", account: account) #it will call a view. Create a view with same name of the controller
      end
  end

  def withdraw(conn, params) do
    with {:ok, %Account{} = account} <- Rocketpay.withdraw(params) do
      conn
      |> put_status(:ok) # http 201
      |> render("update.json", account: account) #it will call a view. Create a view with same name of the controller
      end
  end

  def transaction(conn, params) do
    with {:ok, %TransactionResponse{} = transaction} <- Rocketpay.transaction(params) do
      conn
      |> put_status(:ok) # http 201
      |> render("transaction.json", transaction: transaction)
      end
  end

end
