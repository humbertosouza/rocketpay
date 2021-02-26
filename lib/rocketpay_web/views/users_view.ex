defmodule RocketpayWeb.UsersView do #same name from the controller, so it renders correctly
  alias Rocketpay.{User, Account}
  def render("create.json", %{
      user: %User{account: %Account{id: account_id, balance: balance}, id: id, name: name, nickname: nickname}
      }) do
    %{
      message: "User Created",
      user: %{
        id: id,
        name: name,
        nickname: nickname,
        account: %{
          id: account_id,
          balance: balance
        }
      }
    }

  end
end
