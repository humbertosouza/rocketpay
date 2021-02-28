defmodule RocketpayWeb.AccountsView do #same name from the controller, so it renders correctly
  alias Rocketpay.Account
  alias Rocketpay.Accounts.Transaction.Response, as: TransactionResponse

  # The file name in accounts_view is update.json, so it should be rendered here
  def render("update.json", %{account: %Account{id: account_id, balance: balance}}) do
    %{
      message: "Balance changed succesfully",
        account: %{
          id: account_id,
          balance: balance
      }
    }
  end

  # The file name in accounts_view is update.json, so it should be rendered here
  def render("transaction.json", %{
    transaction: %TransactionResponse{to_account: to_account, from_account: from_account}}) do
    %{
      message: "Transaction done succesfully",
        transaction: %{
          from_account: %{
            id: from_account.id,
            balance: from_account.balance
          },
          to_account: %{
            id: to_account.id,
            balance: to_account.balance
          }
      }
    }
  end
end
