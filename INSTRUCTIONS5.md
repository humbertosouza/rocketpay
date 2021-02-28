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

### 1 - User's create test

Create the file `test/rocketpay/users/create_test.exs` and its content should be

```elixir
defmodule Rocketpay.Users.CreateTest do
  # Add Test to the end of the module name.any so it will call name.anyTest

  # We are not using the ExUnit, but using Datacase that includes ExUnit and have some
  #  helper functions that help with the database rollback after the tests and
  #  pattern matching for assertion in the errors_on() function.
  use Rocketpay.DataCase

  alias Rocketpay.User
  alias Rocketpay.Users.Create  # For testing

  describe "call/1" do
    test "When all params are valid, returns an user" do
      params = %{
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
      assert %User{name: "Humberto", age: 27, id: ^user_id} = user

    end


    test "When there are invalid params, returns an user" do
      params = %{
        name: "Humberto",
        nickname: "gostoso",
        email: "test@email.com",
        age: 19
      }

      {:error, changeset} = Create.call(params)

      expected_response = %{
          age: ["must be greater than or equal to 18"],
          password: ["can't be blank"]
      }
      # the ^ means it is the PIN operator. If  there is no ^ the test would pass. But the PIN fix the value
      # it is using PIN and = . The ID is generated automatically, and the value will be a new value.
      # It will assure the reading before using it.

      #assert "banana" == errors_on(changeset) # Use this for checking/matching the errors before implementing
      #                                          The real case.
      assert errors_on(changeset) == expected_response
    end
  end
end
```

Notice that the `Rocketpay.DataCase` is being used in this test. Click on CTRL+function to get to it and find the function `errors_on(changeset)`. We are interested in using this function to compare to all expected responses.

Another feature is that the `data_case.ex` setups the database as Ecto sandbox. Check the `setup tags do` for learning more. It runs all the tests, and after the tests, it runs rollback of everything and the DB remains clean. 

### 2 - Creating a controller test

Create a test for accounts_controller.ex. Create the file `test/rocketpay_web/controllers/accounts_controller.exs` and add the following:

```elixir
defmodule RocketpayWeb.AccountsControllerTest do

end
```
`RocketpayWeb.ConnCase` will be used for arraging the controller functionalities for this test.

Remember that controller transactions must be authenticated.

Correct the file name to be `accounts_controller_test.exs` otherwise it will not run the tests;

There are some debug involved in this test. There are updates applied to the source codes for `withdraw.ex` and `deposit.ex` to provide the correct returns from the `run_transaction` function.

Some debugs advices are found in the source code below as well.

```elixir
defmodule RocketpayWeb.AccountsControllerTest do

  # This will help because we have controller functionalities to be used in this test.
  use RocketpayWeb.ConnCase

  alias Rocketpay.{Account, User}

  # it is deposit/2 as it expects the connection and the paramenters
  describe "deposit/2" do
    # User creation will require a setup
    setup %{conn: conn} do
      params = %{
        name: "Humberto",
        password: "nan1234",
        nickname: "gostoso",
        email: "test@email.com",
        age: 27
      }

      {:ok, %User{account: %Account{id: account_id}}} = Rocketpay.create_user(params)

      #Here the authentication needs to be set in order to run the POST commands adequately
      # for the expected tests. Fill the line below as the result of the
      # previous result of the basic authentication `iex()>Base.encode64("banana:nanica123")`
      # The put_req_header will add the field/value to the header.
      conn = put_req_header(conn, "authorization", "Basic YmFuYW5hOm5hbmljYTEyMw==" )

      # The end of a setup a tuple having :ok and key/value are always required
      {:ok, conn: conn, account_id: account_id}
    end

    test "when all params are valid, execute the deposit", %{conn: conn, account_id: account_id} do
      params = %{"value" => "50.00"}

      # Use the helper from the ConnCase controller to find the account route
      # Post calls the same post as Postman/Insomnia
      # The format is Routes.accounts_path(connection, action(deposit), id (part of the URL), parameters)
      # When using json_response in tests for encoding the response, we need to provide the valid
      #  match verb(:ok) because the test will validate it.
      # json_response(:ok) will not work because the transaction is not authenticated.
      response =
        conn
        |> post(Routes.accounts_path(conn, :deposit, account_id, params))
        |> json_response(:ok)

      # For testing the output, do this first
      # assert  response == banana
      # Copy the values from the test results

      # For the real test, we cannot use == but the pattern match because the id varies every time
      # We need to ignore the id by making _id

      # HOWEVER, the code below expects the balance to change, but it came zero
      assert %{
                "account" => %{"balance" => "50.00", "id" => _id },
                "message" => "Balance changed succesfully"
              } = response

      # You may debug the code to find where the issue is by using IO.inspect() within the pipes
      # |> ...
      # |> IO.inspect()
      # |> ...

      # the problem was in the deposit.ex. Check it by changing the `defp run_transaction(multi) do
      # Check the comments there for more details.
    end
  end
end
```

Remember of removing IO.inspect() calls.

Add the second test to the module following the below code (basically a copy of the uncommented above code). The important point are the messages and the wrong value

```elixir
    test "when there are invalid params, returns an error", %{conn: conn, account_id: account_id} do
      params = %{"value" => "banana"}

      response =
        conn
        |> post(Routes.accounts_path(conn, :deposit, account_id, params))
        |> json_response(:ok)

      assert %{
                "account" => %{"balance" => "50.00", "id" => _id },
                "message" => "Balance changed succesfully"
              } = response
    end
```
Run the test and notice that it returns a 400 error. Please update the json_response to `json_response(:bad_request) #400`

Now it will pass the 400, but match incorrect message. Correct the expected message to `Invalid operation value!`

Even though `assert %{"message" => "Invalid operation value!"} = response` works, we don't need it anymore as we can ulse the `==` as there are no dynamic values to be checked, and it is used on the LEFT side of the function. It can be replaced by:

```elixir
      expected_value = %{
        "message" => "Invalid operation value!"
      }

      assert  expected_value == response
```

You could add tests to check if the authentication is not present, or if it is an invalid UUID and so on.

Generate the report mix coverals.html and check that now we cover 57% of the code. :)

### 3 - Testing a view

Create the file `test/rocketpay_web/controllers/views/users_view_test.exs`

Copy the content of the users_view.ex file to the new file, leaving the first and last line and adding the `Test` keyword to its module name.

Make the code be like the following paying attention to its comments.

```elixir
defmodule RocketpayWeb.UsersViewTest do #same name from the controller, so it renders correctly
  # Uses the same ConnCase module
  use RocketpayWeb.ConnCase

  # This make the 'render' function available
  import Phoenix.View

  alias Rocketpay.{Account, User}
  alias RocketpayWeb.UsersView

  # The test below has no describe because it is a single function test module, for rendering
  #  so there is no need for the description in this view, even though it could be done.
  # Phoenix itself follows this standard - check the file error_view_test.exs file in the same folder.

  # Lets create the user
  # *** The view is called only in case of success ***
  # Copy the parameters from the create_test.exs
  test "renders create.json" do
    params = %{
      name: "Humberto",
      password: "nan1234",
      nickname: "gostoso",
      email: "test@email.com",
      age: 27
    }

    {:ok, %User{id: user_id, account: %Account{id: account_id}} = user} = Rocketpay.create_user(params)

    response = render(UsersView, "create.json", user: user )

    # this is to fail the test and create the correct response.
    #assert "banana" == response

    # As some data is variable, copy the `mix test` output of this test and past it here.
    #assert %{message: "User Created", user: %{account: %{balance: #Decimal<0.00>, id: "37231f7a-54a9-4337-ae25-3e311d18cf1d"}, id: "c6a50e9f-629a-4be9-a67b-87aa600bfb50", name: "Humberto", nickname: "gostoso"}} = response

    #Change #Decimal<"0.00"> to Decimal.new("0.00")
    # it will also use the account_id above and the user_id above
    expected_response = %{message: "User Created",
      user:
        %{account:
          %{balance:
              Decimal.new("0.00"),
              id: account_id
          },
          id: user_id,
          name: "Humberto",
          nickname: "gostoso"
        }
      }

    # In this case, we can use  the  == because we created the response and all required variables BEFORE
    #  this function is invoked.
    assert expected_response == response
  end
end
```
### Test summaries

The most important thing is how to structure tests for views, controllers and unit tests.

A challenge would be covering the remainder tests.
The tests take 1.5 second because of the DB usage.

Now you can add the async = true to the tests created so far:
`use Rocketpay.DataCase` should be `use Rocketpay.DataCase, async: true`

The files covered so far are:

`create_test.exs`

`users_view_test.exs`

`accounts_controller_test.exs`

`numbers_test.exs` to the ExUnit

Run the tests again using `mix test`. They should run faster this time.

The flag async: true makes everything run in parallel. Some services may require that there is no concurrence (as using sequential ids) where async true may fail some of your tests.

### The extra mile

You can go beyond and add new cases, missing tests.
It is also interesting to process parallel tasks and files

### Final remarks

Elixir has amazing functional syntax. However, the Phoenix framework is still verbose when comparing Java + Spring.






























