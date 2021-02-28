# Elixir - JSON backend payment app - Part 3

Remember:

`%User{}` is a struct. 

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

```elixir 
  import Ecto.Changeset, only: [traverse_errors: 2]   # bring from module the function.
                                                      # Like Python, it allow you to call the function
```

Add the 2 functions to the file:

```elixir
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

```elixir
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

```elixir
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

```elixir
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

```elixir
defmodule Rocketpay.Repo.Migrations.CreateAccountsTable do
  use Ecto.Migration

  def change do
    create table :accounts do
      add :balance, :decimal # for monetary values, ecto uses this DECIMAL type
      add :user_id, references(:users, type: :binary_id)

      timestamps()

    end

    # Constraints brings part of the logic to the DB>
    # This is to assure the user will not be with negative balance
    create constraint(:accounts, :balance_must_be_positive_or_zero, check: "balance >= 0")

  end
end
```

Run the command `$mix ecto.migrate` and call `iex -S mix`

Now lets create the schema. 

Create the file under lib/rocketpay the file `account.ex` 

Copy the content from the file user.ex to account.ex, replacing the lines. The line one should have Account instead of User, and so on.

It should look like the following:

```elixir
defmodule Rocketpay.Account do
  # Map the schema. Schema is the closest thing to the model, but it is only data mapping here.any()
  use Ecto.Schema
  import Ecto.Changeset

  alias Rocketpay.User

  @primary_key {:id, :binary_id, autogenerate: true} #Binary_ID means UUID.
  @foreign_key_type :binary_id#Binary_ID means UUID.

  @required_params [:balance, :user_id] #mandatory fields
  # :value are atoms - string constants

  schema "accounts" do
    field :balance, :decimal  #For monetary values
    belongs_to :user, User

    # means that it belongs to the user schema
    timestamps() #Must be present as the fields are mandatories
  end

  #Changeset maps and validate data.
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @required_params) #cast convert the struct to a changeset (check with IO.Inspect())
    |> validate_required(@required_params) #check all required params
    |> check_constraint(:balance, name: :balance_must_be_positive_or_zero)

  end
end
```
You may create an account manually.

Open again the `$iex -S mix`

`iex()> Rocketpay.Repo.all(Rocketpay.User)`

Create a map having the following parameters. Note that Ecto casts the string to number for us.

`params = %{user_id: "61488455-f159-4fcf-a57c-f026de526b30", balance: "0.00"}`

Then add the params to changeset

`params |> Rocketpay.Account.changeset()`

Now lets try to add it to Accounts table

`params |> Rocketpay.Account.changeset() |> Rocketpay.Repo.insert()`

If you run again `iex()> Rocketpay.Repo.all(Rocketpay.User)` you will not find any reference to the user's account. For assuring it, go back to the /lib/rocketpay/user.ex and add has_ to it:

```elixir
...
alias Rocketpay.Account
alias Ecto.Changeset

schema "users" do 
    ...
    has_one :account, Account
    ...
```
Check in iex: `iex()>recompile` then `iex()> Rocketpay.Repo.all(Rocketpay.User)`  for checking the account: ... related information. It is not loaded by default.

However, Ecto will not load by default to avoid overflowing excessive data querying. If one's want to get info from accounts, do the following:

`iex()>Rocketpay.Repo.all(Rocketpay.User) |> Rocketpay.Repo.preload(:account)`

If the account has been correctly related, it should show

```elixir
[ 
  ...
  %Rocketpay.User{
    __meta__: #Ecto.Schema.Metadata<:loaded, "users">,
    account: %Rocketpay.Account{
      __meta__: #Ecto.Schema.Metadata<:loaded, "accounts">,
      balance: #Decimal<0.00>,
      id: "84e95b30-d3a1-4c48-abe2-cc322bac51c4",
      inserted_at: ~N[2021-02-26 02:16:18],
      updated_at: ~N[2021-02-26 02:16:18],
      user: #Ecto.Association.NotLoaded<association :user is not loaded>,
      user_id: "61488455-f159-4fcf-a57c-f026de526b30"
    }, 
    age: 27,
    email: "joao3@test.com.br",
    id: "61488455-f159-4fcf-a57c-f026de526b30",
    inserted_at: ~N[2021-02-25 03:27:37],
    name: "Joao3",
    nickname: "john3",
    password: nil,
    password_hash: "$2b$12$bHzSHrXqByYwB/21Wr2eeO20hXDWiTc5Qg9/1z8vsFyt17xlDMjZS",
    updated_at: ~N[2021-02-25 03:27:37]
  }
]
```

Now we should allow the system to create an user along with an account, all at once, saving requests and potentially transactions.

Check the Ecto Multi on https://hexdocs.pm/ecto/Ecto.Multi.html It is quite similar to Repo but less functionalities as it is more specific. 

The new `lib/rocketpay/users/create.ex` should look like the following

```elixir
defmodule Rocketpay.Users.Create do

  alias Rocketpay.{User, Repo, Account} #creating 2 aliases at same time
  alias Ecto.Multi


  def call(params) do
    Multi.new() # This starts a multi operation
    |> Multi.insert(:create_user, User.changeset(params)) # Insert user, operation name is :create_user
                                                          # It calls user, but it expects a changeset
    |> Multi.run(:create_account, fn repo, %{create_user: user} ->
          # repo.insert(account_changeset(user.id)) end)
                                       # Creates the function name and add an anonymous function to it
                                       # It expects an anonymous function. It expects the rep and the map that
                                       # is the response of the previous function
                                       # this function could be also replaced by
                                       #
                                       # user.id
                                       # |> account_changeset()
                                       # |> repo.insert()
                                       #
                                       # but we can create another private function.
          insert_account(repo, user) end)    # Updated and readable function
    |> Multi.run(:preload_data, fn repo, %{create_user: user} ->
          preload_data(repo, user) end)

    #For transactions, createthe run_transaction below
    |> run_transaction()

    # params
    # |> User.changeset()
    # |>Repo.insert()
  end

  # for adding the preload data
  defp preload_data(repo, user) do
    {:ok, repo.preload(user, :account)}
  end

  defp insert_account(repo, user) do
    user.id
    |> account_changeset()
    |> repo.insert()
  end

  #one-liner
  #defp account_changeset(user_id), do: Account.changeset(%{user_id: user_id, balance: "0.00"})

  defp account_changeset(user_id) do
    params = %{user_id: user_id, balance: "0.00"}
    Account.changeset(params)
  end

  defp run_transaction(multi) do
    case Repo.transaction(multi) do
      {:error, _operation, reason, _changes} -> {:error, reason} #dont care the 2nd and 4th parameters
      {:ok, %{preload_data: user}} -> {:ok, user}
    end
  end

end

```

Then try recompile using iex and run

`iex()> params = %{name: "Humberto1", password: "123456", nickname: "beto1", age: 41, email: "humberto1@ited.com.br"}`

`iex()>Rocketpay.create_user(params)`

The account has been created and the account was returned instead of the user. 

For running it in full, you can call preload_data modules described above.

## Views

Now that data is made available, the view can be created.

Go to Rocketpayweb/view/user_view.ex and update the file accordingly

```elixir
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
```

Now run the `$mix phx.server`, go to the Insomnia/Postman and create a new user with account using the POST endpoint `http://localhost:4000/api/users`.

## Account transactions

Now you should be able to create POST withdraw and deposits endpoints.

http://localhost:4000/api/accounts/<uudi_account>/deposit

http://localhost:4000/api/accounts/uudi_account/withdraw

JSON
{
    "value":120.2
}

For this, add the following lines to your router.ex file:

```elixir
    post "/accounts/:id/deposit", AccountsController, :deposit
    post "/accounts/:id/withdraw", AccountsController, :withdraw
```

Create the file /lib/rocketpay_web/controllers/accounts_controller.ex

You may copy its contents from users_controller.ex and edit accordingly or make the code as following

```elixir
defmodule RocketpayWeb.AccountsController do
  use RocketpayWeb, :controller

  alias Rocketpay.Account

  action_fallback RocketpayWeb.FallbackController

  #%Account{} is a struct

  def deposit(conn, params) do
    with {:ok, %Account{} = account} <- Rocketpay.deposit(params) do

      conn
      |> put_status(:ok) # http 201
      |> render("update.json", account: account) #it will call a view. Create a view with same name of the controller
      end

  end

end
```

Go to the file `/lib/rocketpay.ex` and add the folloing defdelegates:

```elixir
  alias Rocketpay.Accounts.Deposit
  ...

  defdelegate deposit(params), to: Deposit, as: :call
  
```

Note that the responsibilites of each API call are well defined.

Now lets create the module by creating a folder at `lib/rocketpay/accounts`

Inside it, create the `deposit.ex` file. Make it as following

```elixir
defmodule Rocketpay.Accounts.Deposit do
  alias Ecto.Multi

  alias Rocketpay.{Account, Repo}

  # It is just an account update, however, the account may exist or not..
  # We try to read the account and update the statement. If OK, then finish.
  # There is no get on Multi .... but you can run anything using .run
  # Use acconut, repo, _changes are not needed, and we need to pattern match id

  # read id and value via pattern match
  def call(%{"id" => id, "value" => value}) do
    Multi.new()
    |>Multi.run(:account, fn repo, _changes -> get_account(repo, id) end)
    |>Multi.run(:update_balance, fn repo, %{account: account} -> update_balance(repo, account, value) end)
    |>run_transaction()
  end

  defp get_account(repo, id) do
    case repo.get(Account, id) do
      nil -> {:error, "Account not found!"}
      account -> {:ok, account}
    end
  end

  # We need to sum/subtract the value
  # We also need to check if the value is valid
  defp update_balance(repo, account, value) do
    account
    |> sum_values(value)
    |> update_account(repo, account)
  end

  # If you are working with financial data, use the lib decimal.
  # Phoenix + Ecto make this lib available by default.

  defp sum_values(%Account{balance: balance}, value) do
    value
    |> Decimal.cast()
    |> handle_cast(balance)
  end

  defp handle_cast({:ok, value}, balance), do: Decimal.add(value, balance)
  defp handle_cast(:error, _balance), do: {:error, "Invalid deposit value!"}



  # The last step for updating account
  defp update_account({:error, _reason} = error, _repo, _account), do: error
  defp update_account(value, repo, account) do
    params = %{balance: value}
    params
    |>Account.changeset(account)
    |>repo.update()

  end

  #Now you can copy and adapt the run_transaction code from create.ex
  defp run_transaction(multi) do
    case Repo.transaction(multi) do
      {:error, _operation, reason, _changes} -> {:error, reason} #dont care the 2nd and 4th parameters
      # last transaction from multi is update_balance, as following
      #     |>Multi.run(:update_balance, fn repo, %{account: account} -> update_balance(repo, account, value) end)
      {:ok, %{update_balance: account}} -> {:ok, account}
    end
  end

end

```

Init the iex `$iex -S mix` and type `iex()>Decimal.cast("50.55")` and `iex()>Decimal.cast("banana")`

Then try it, getting the latest account ID available:
```elixir
iex()>Rocketpay.Repo.all(Rocketpay.Account)
iex()>Rocketpay.deposit(%{"id" => "2eeb172c-a881-4463-b949-a44d1944be81", "value" => "50.0"})
```
You will notice that the it is missing the user id.

On account.ex, change the header of the following function to have the struct as input, and if no data is added, \\ indicates the default value, that in this case, is a empty module struct

```elixir
  #Changeset maps and validate data.
  # struct module has moved to the function parameters. It can be a empty struct OR a struct that have value
  # \\ indicates a DEFAULT parameters, that is the empty struct
  def changeset(struct \\ %__MODULE__{}, params) do
    struct
```

Update the deposit.ex update_account function to match the new order (account, params) to match
```elixir
  defp update_account(value, repo, account) do
    params = %{balance: value}
    account
    |>Account.changeset(params)
    |>repo.update()
  end
```

Now recompile in iex and try again.

If running `Rocketpay.deposit(%{"id" => "2eeb172c-a881-4463-b949-a44d1944be81", "value" => "50.0"})` multiple times, the balance is expected to grow.





















