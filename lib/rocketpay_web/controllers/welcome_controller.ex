defmodule RocketpayWeb.WelcomeController do
  use RocketpayWeb, :controller


#  def index(conn, _params) do
#    text(conn, "Welcome to the Rocketpay API")
#  end

  alias Rocketpay.Numbers

  def index(conn, %{"filename" => filename}) do #This saves the pattern match into a variable filename.
                                                # in the iex, it uses string: value; but in the controller "string => value

    filename
    |> Numbers.sum_from_file()
    |> handle_response(conn) #conn is the second parameter!

  end

  defp handle_response({:ok, %{result: result}}, conn) do
    conn
    |> put_status(:ok)
    |> IO.inspect()
    |> json(%{message: "Welcome to Rocketpay API. Here is your number #{result}"})
  end

  defp handle_response({:error, reason}, conn) do
    conn
    |> put_status(:bad_request)
    |> json(reason)
  end



end
