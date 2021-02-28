# Elixir - Authentication, Tasks and process - Part 5

## Tasks and Processes

Each request that controllers receives in Elixir is a process executed separately. A process is generaly expensive to be created. However, the BIN, the Erlang VM has its own process that are extremely lightweight, fast and use low memory and can be created in bulks of thousands.

Even if a process breaks, raise errors, it will not affect other processes or the main thread, because EACH request will be a separated and independent process, and variable do not change or lock. Every function return a new variable in a new position in memory.

## Async Await

Elixir has the "Async Await" paradigms.  

For illustrate it, open the `lib/rocketpay_web/controllers/accounts_controller.ex` and add to the transaction function at its first line the `Task.async(fn -> Rocketpay.transaction(params) end)`. Task.async expects an anonymous function that does the concurrent task.This would be enough for creating a concurrent task.

However, as it is async, it is necessary to assign a variable in order to use await.
`task = Task.async(fn -> Rocketpay.transaction(params) end)`

`result = Task.await(task)` will wait the task to execut and have the result of it. 

Another way for implement as following. 

```elixir
  def transaction(conn, params) do
    task = Task.async(fn -> Rocketpay.transaction(params) end)

    # Other tasks could run here before the result is delivered.
    # ...
    # ...

    #result = Task.await(task) # It could be here
    with {:ok, %TransactionResponse{} = transaction} <- Task.await(task) do
      conn
      |> put_status(:ok) # http 201
      |> render("transaction.json", transaction: transaction)
      end
  end
```
Do so and run the server: `$mix phx.server`

Then run Insomnia/ Postman for transaction and it should work as usual.

POST `http://localhost:4000/api/accounts/transaction`

```json
{
    "value":"5.5",
    "from":"f4035d76-2870-4b62-a36b-9480284e44df",
    "to":"84e95b30-d3a1-4c48-abe2-cc322bac51c4"
}
```
The overall behaviour did not change in usage. Notice the comments in the code: "Other tasks could run here before the result is delivered". 

Now you could replace the comment above on transaction by
```elixir
 # Other tasks could run here before the result is delivered.
    # ...
    # ...
    IO.puts("Hi 1")
    IO.puts("Hi 2")
    IO.puts("Hi 3")
    IO.puts("Hi 4")
    IO.puts("Hi 5")
    IO.puts("Hi 6")
```

And add the following to the `lib/rocketpay/accounts/tranasctions.ex`:

```elixir
  ...
  def call(%{"from" => from_id, "to" => to_id, "value" => value}) do
    withdraw_params = build_params(from_id, value)
    deposit_params = build_params(to_id, value)

    IO.puts("We are inside the transaction") # <<<=== Add this line 
    ...
```

Start the server `$mix phx.server` and run the transaction endpoint a couple of times. Something as follows should show up in the log

```json
Hi 1
We are inside the transaction
Hi 2
Hi 3
Hi 4
Hi 5
Hi 6
```

Data does not change in memory. On the database, we use transaction (everything runs or not) and tasks are simple in Ellipse as there are way less points to check

Other way to utilize the Tasks is  changing the function accounts_controller.ex to reply to the user something that could take 30 minutes to execute. Update the file `accounts_controller.ex` and try the following
```elixir
  def transaction(conn, params) do
    task = Task.async(fn -> Rocketpay.transaction(params) end)

    # Other tasks could run here before the result is delivered.
    # ...
    # ...
    conn
    |> put_status(:no_content) # http 204
    |>text("")
  end  
```

Run the end point and check it.

We could run 10 tasks in parallel and aggregate the values. Now return the code to the previous state:
```elixir
  def transaction(conn, params) do
    with {:ok, %TransactionResponse{} = transaction} <- Rocketpay.transaction(params) do
      conn
      |> put_status(:ok) # http 201
      |> render("transaction.json", transaction: transaction)
      end
  end
```

And delete the `IO.puts("We are inside the transaction")` line from the transaction.ex file.

## Authentication

This current API is completely open and requires authentication. The correct way is to create JWT tokens having expiration self-signed, having the secret. 

The authentication shown here will be simplified for the sake of the time. 

The basic_auth will be utilized in this case. Open the file `config.exs` and create the following entry, after `config :rocketpay, Rocketpay.Repo,`:

```elixir
config :rocketpay, :basic_auth,
  username: "banana",
  password: "nanica123"
```

Now using the `lib/rocketpay_web/router.ex` add the followign

```elixir
  pipeline :auth do
    plug :basic_auth, Application.compile_env(:rocketpay, :basic_auth)
  end
```
Application.compile_env in compile time it will read the configuration passed the  config.exs values (the credentials). If it was real life, it would be environment variables, not stick to the code, using systm.get_env.

Plugs are conventions of module composition. The plugs used in this code have been created by Phoenix, but you could create modules that receive the connection and change it. You could find about plugs in the documentation.

And create the following scope

```elixir
efmodule RocketpayWeb.Router do
  use RocketpayWeb, :router

  import Plug.BasicAuth

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug :basic_auth, Application.compile_env(:rocketpay, :basic_auth)
  end

  scope "/api", RocketpayWeb do
    pipe_through :api

    #get "/", WelcomeController, :index
    get "/:filename", WelcomeController, :index

    post "/users", UsersController, :create


  end

  scope "/api", RocketpayWeb do
    pipe_through [:api, :auth]

    post "/accounts/:id/deposit", AccountsController, :deposit
    post "/accounts/:id/withdraw", AccountsController, :withdraw

    post "/accounts/transaction", AccountsController, :transaction

  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: RocketpayWeb.Telemetry
    end
  end
end

```

In route.ex, a pipeline was create. All routes under (using) pipe_through must follow the scope and include basic_auth, and everything must be JSON but also need to be authenticated. 


Now try using basic_auth in Insomnia/Postman:
with the POST `http://localhost:4000/api/accounts/transaction`
username:banana
password:nanica123

And it should work. Other usernames and password combinations should issue a 'Unauthorized'  as response.


You can also create the header from scratch:

Content-Type: application/json

Authentication: basic username:password

However, the username:password combination must be  base64.
You can convert it using `iex()>Base.encode64("banana:nanica123")` which results `"YmFuYW5hOm5hbmljYTEyMw=="`

The header should look like

Content-Type: application/json

Authentication: basic YmFuYW5hOm5hbmljYTEyMw==

* It is NOT a good practice using this authentication in production. 

## Tests

When using `mix test --cover` a report will tell how much of the application is covered. It is 13% so far. The goal is having always 100% of the code covered. The report will show which files needs to be covered. It does not show the lines, the details. 

The lib `excoveralls` in the test environment. Add it to the file `mix.exs` file:
`{:excoveralls, "~> 0.10", only: :test}`

Copy the extract below from `https://github.com/parroty/excoveralls` to the `mix.exs` file, after the deps:

```elixir
    test_coverage: [tool: ExCoveralls],
    preferred_cli_env: [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.post": :test,
      "coveralls.html": :test
    ]
```
and it should look like

```elixir
  def project do
    [
      app: :rocketpay,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]      
    ]
  end
```

As soon as it is saved, run the `$mix test --cover` again. It should show more detailed information.

Even better, you could use `$mix coveralls.html` you can copy the file URL by copying the path from VS Code to the browser.

Now let's create some tests.
So one test per type (changeset, controller, view) can be tried.

1 - User's create test

Create the file `test/rocketpay/users/create_test.exs` and its content should be

```elixir
defmodule Rocketpay.Users.CreateTest do
  # Add Test to the end of the module name.any()
  # We are not using the ExUnit
  use Rocketpay.DataCase

  alias Rocketpay.User
  alias Rocketpay.Users.Create  # For testing

  describe "call/1" do
    test "When all params are valid, returns an user" do
      params =%{
        name: "Humberto",
        password: "nan1234",
        nickname: "gostoso",
        email: "test@email.com",
        age: 27
      }

      {:ok, %User{id: user_id}} = Create.call(params)
      # Check if it is in the data
      user = Repo.get(User, user_id)
      # the ^ means it is the PIN operator. If  there is no ^ the test would pass. But the PIN fix the value
      # it is using PIN and = . The ID is generated automatically, and the value will be a new value.
      # It will assure the reading before using it.
      assert %User{name:"Humberto", age: 27. id: ^user_id} = user

    end

    test "When there are invalid params, returns an error" do
      params =%{
        name: "Humberto",
        nickname: "gostoso",
        email: "test@email.com",
        age: 27
      }

      {:error, changeset} = Create.call(params)

      expected_response = %{
          age: ["Must be greater than or equal to 18"],
          password: ["Cant be blank"]
      }  
      # the ^ means it is the PIN operator. If  there is no ^ the test would pass. But the PIN fix the value
      # it is using PIN and = . The ID is generated automatically, and the value will be a new value.
      # It will assure the reading before using it.
      assert errors_on(changeset) = expected_response
    end
  end
end
```









