defmodule RocketpayWeb.UsersView do #same name from the controller, so it renders correctly
  alias Rocketpay.User
  def render("create.json", %{user: %User{id: id, name: name, nickname: nickname}}) do
    %{
      message: "User Created",
      user: %{
        id: id,
        name: name,
        nickname: nickname
      }
    }

  end
end
