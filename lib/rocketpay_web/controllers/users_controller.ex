defmodule RocketpayWeb.UsersController do
  use RocketpayWeb, :controller

  alias Rocketpay.User

  def create(conn, params) do # Action
    params
    |> Rocketpay.create_user()
    |> handle_response(conn) #conn is the second parameter!

  end

  defp handle_response({:ok, %User{} = user}, conn) do
    conn
    |> put_status(:created) # http 201
    |> render("create.json", user: user) #it will call a view. Create a view with same name of the controller
  end

  defp handle_response({:error, result}, conn) do
   conn
    |> put_status(:bad_request)
    |> put_view(RocketpayWeb.ErrorView)
    |> render("400.json", result: result)
  end

end
