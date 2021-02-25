defmodule RocketpayWeb.UsersController do
  use RocketpayWeb, :controller

  alias Rocketpay.User

  action_fallback RocketpayWeb.FallbackController

  def create(conn, params) do # Action
    # with is pattern match as well. Whenever it does not match (not OK), it returns the error to phx.
    # however, it is passed to the declared fallbackcontroller
    # We could have chained matchings... with are of good usage in controllers, not in lib

    with {:ok, %User{} = user} <- Rocketpay.create_user(params) do

      conn
      |> put_status(:created) # http 201
      |> render("create.json", user: user) #it will call a view. Create a view with same name of the controller
      end
  # response try to handle all functions (update, show, etc)
  end

end
