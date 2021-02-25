# Elixir - JSON backend payment app - Part 3

## Repo.<tab>

Application.Repo. contains a list of commands, most related to database instructions.

For more info, access the `$iex -S mix` and issue e.g `h Rocketpay.Repo.all()`

Online documentation is also available on the https://hexdocs.pm/ecto/Ecto.html

E.g.

`Rocketpay.Repo.All(Rocketpay.User)`

It brings all records from table users.

## Controller - Exceptions and errors

`rocketpay_web/controllers/users_controller.ex` checks the file `rocketpay_web/views/errors_view.ex` For the message rendering.

Update the file `rocketpay_web/views/errors_view.ex` to add extra information than `Bad Request` in the JSON response.

Create the functions as below. Check the documentation for traverse_errors to get the function

Add the import so that the function can be called directly.

```javascript 
  import Ecto.Changeset, only: [traverse_errors: 2]   # bring from module the function.
                                                      # Like Python, it allow you to call the function
```

Add the 2 functions to the file:

```javascript
  alias Ecto.Changeset
  # def render("400.json", %{result: changeset}) do  # Matching the 400.json and the changesett
  def render("400.json", %{result: %Changeset{} = changeset}) do   # Even better, lets do the pattern matching so that
                                                     #  the function only matches with
    %{message: translate_errors(changeset)}
  end

  # Search in the documentation for traverse_errors
  defp translate_errors(changeset) do
    traverse_errors(changeset, fn {msg, opts} -> # same as Ecto.Changeset.traverse_errors
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
```
Using Insomnia or Postman, call the API POST endpoint http://localhost:4000/api/users 

With the following JSON content

```javascript
{
    "name":"Joao2",
    "nickname": "john2",
    "age": 27,
    "email": "joao2@test.com.br",
    "password": "1234"
}
```

The error response shouw show the password error (at least 6 characters).

## Fallback controller

It is straighforward successful operations. For the file `users_controller.ex`, we have handle for each function - create, update, show, etc. It will become big and hard to read.

Aftter alias, add to users_controller.ex file

`  action_fallback RocketpayWeb.FallbackController`

and delete the content of the handle_response - error. Make it like the following.

`  defp handle_response({:error, _result} = error, _conn), do: error`

We are already using the `handle_response` function for the error handling.

For the Fallback, create the file `rocketpay_web/controllers/fallback_controller.ex`

Add the following content to it.

```javascript
defmodule RocketpayWeb.FallbackController do
  use RocketpayWeb, :controller

  def call(conn, {:error, result}) do # Standard function for fallbacks
    IO.puts("I was called!") #NOT NEEDED
    conn
    |> put_status(:bad_request)
    |> put_view(RocketpayWeb.ErrorView)
    |>render("400.json", result: result)

  end
end
```
Go to the Postman / Insomnia and call again the erroneous JSON and check if the error message still works

## Eliminating handle_response

Update the file rocketpay_web/controllers/users_controller.ex as stated below.

```javascript
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
```

Go to the Postman / Insomnia and test a valid and invalid data. It should work.

## Creating Users accounts 

Create a accounts table

`$mix ecto.gen.migration create_accounts_table`

Find your new migration under priv/repo/migrations/< code >_create_accouts_table.exs







