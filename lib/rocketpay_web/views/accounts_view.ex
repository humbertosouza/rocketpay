defmodule RocketpayWeb.AccountsView do #same name from the controller, so it renders correctly
  alias Rocketpay.Account

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
end
