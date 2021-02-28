# Elixir - JSON backend payment app - Part 4

Remember:

Functional programming and lambda functions.
If you open the `$iex`, you may try something through list creation `list = [1,2,3,4]` then run a Enum.map or Enum.reduce to call a anonymous function and proceed a calculation with the list

`Enum.map(list, fn number -> number * 2 end)` Means that for each number in this list will be taken, then the number will be multiplied by 2. The base function takes data and decompose it within the anonymous function. 

## Creating the View

Create the file `lib/rocketpay_web/views/accounts_view.ex` and make it like the following extract

```elixir
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
```

And call this function from Postman / Insomnia via POST from the following URL (please replace the UUID):
`http://localhost:4000/api/accounts/2eeb172c-a881-4463-b949-a44d1944be81/deposit`
Body: `{ "value:"55.0"}`

And it should work.

The error message is still default if a invalid value is passed.
For fixing this, add to the lib/rocketpay_web/views/error_view.ex the following:

```elixir
  # It takes the message that comes from the controller and render to the view
  def render("400.json", %{result: message}) do
    #  the function only matches with
    %{message: message}
  end

```

Now run it with the wrong boddy message, invalid value and the messages should appear to the API.

Again, it is not a good practice use the float for financial values, because each CPU handles the floats differently.
In the database, we multiply by 100 or use libs like decimal and use the Decimal.cas("50.00")

The lib decimal is not explicitly declared on the mix.exs file, because Ecto uses it. However, in future,
if Ecto must be replaced, you would need to add Decimal to mix.exs
So it is a good idea to add the Decimal to `mix.exs`:

`{:decimal, "~> 2.0"}`

## WithDraw

Add the following piece of code to the `lib/rocketpay/controllers/accounts_controller.ex`. It is a very similar function to deposit.

```elixir
  def withdraw(conn, params) do
    with {:ok, %Account{} = account} <- Rocketpay.withdraw(params) do
      conn
      |> put_status(:ok) # http 201
      |> render("update.json", account: account) #it will call a view. Create a view with same name of the controller
      end
  end
```

Make sure the `router.ex` has the endpoint set:

`post "/accounts/:id/withdraw", AccountsController, :withdraw`

Update the alias to

`alias Rocketpay.Accounts.{Deposit, Withdraw}`

Add to `lib/rocketpay.ex` the following linke

`  defdelegate withdraw(params), to: Withdraw, as: :call`

By copy the content from the file `/lib/rocketpay/accounts/deposit.ex`, create in the same folder the file `withdraw.ex`

As it changed configuration files, the mix phx.server must be reloaded.

## Refactoring the endpoints

This will be done as after creating the deposit and withdraw only the header changes. 
In order to fix this, create the file `lib/rocketpay/accounts/operation.ex` and copy the withdraw.ex content to it.

```elixir
defmodule Rocketpay.Accounts.Operation do
  alias Ecto.Multi

  alias Rocketpay.{Account, Repo}

  # We do not need to use "run transaction"
  # Update update_balance to have repo, account, value and operation.
  def call(%{"id" => id, "value" => value}, operation) do
    Multi.new()
    |>Multi.run(:account, fn repo, _changes -> get_account(repo, id) end)
    |>Multi.run(:update_balance, fn repo, %{account: account} ->
      update_balance(repo, account, value, operation) end)
  end

  defp get_account(repo, id) do
    case repo.get(Account, id) do
      nil -> {:error, "Account not found!"}
      account -> {:ok, account}
    end
  end

  # We need to sum/subtract the value
  # We also need to check if the value is valid
  defp update_balance(repo, account, value, operation) do
    account
    |> operation(value, operation)
    |> update_account(repo, account)
  end

  # renamed sum_values to operation as it does more than one operation
  defp operation(%Account{balance: balance}, value, operation) do
    value
    |> Decimal.cast()
    |> handle_cast(balance, operation)
  end

  #Using patter matching, it will check the third parameter if it is "deposit". If so, add.
  defp handle_cast({:ok, value}, balance, :deposit), do: Decimal.add(balance, value) #inverted when adding
  #Using patter matching, it will check the third parameter if it is "withdraw". If so, subtract.
  defp handle_cast({:ok, value}, balance, :withdraw), do: Decimal.sub(balance, value) #inverted when adding
  # We need to handle the 3 parameter in the error, ignoring the operation
  defp handle_cast(:error, _balance, _operation), do: {:error, "Invalid operation value!"}


  # The last step for updating account
  defp update_account({:error, _reason} = error, _repo, _account), do: error

  defp update_account(value, repo, account) do
    params = %{balance: value}
    account
    |>Account.changeset(params)
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

Then change the withdraw and deposit to the following:

```elixir
defmodule Rocketpay.Accounts.Deposit do

  alias Rocketpay.Accounts.Operation
  alias Rocketpay.Repo

  # ** This has been refactored **
  # It is just an account update, however, the account may exist or not..

  # read id and value via pattern match
  def call(params) do
    params
    |> Operation.call(:deposit)
    |> run_transaction()
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

For the `withdraw.ex` file, change the first line to Withdraw and make the line `|> Operation.call(:deposit)` to be `|> Operation.call(:withdraw)`


Run transaction will be separated for a withdraw from one account implies into a deposit on another, so we will leave this function for working the transfer function.

## Transfers

Create the file `lib/rocketpay/accounts/transaction.ex` and add to it the following content

```elixir
defmodule Rocketpay.Accounts.Transaction do
  alias Ecto.Multi
  alias Rocketpay.Repo
  alias Rocketpay.Accounts.Operation

  # It will require the from_id and to_id in the API call
  # e.g.
  # {
  #    "from_id": "UUID1",
  #    "to_id": "UUID2",
  #    "value": "1.50"
  # }
  # we need to call withdraw and a deposit
  # imagine that the transaction was HALTED half way. It may happen.
  # All of this must happen on a SINGLE TRANSACTION to avoid the above error

  # Ecto.Multi calls are independent but can be merged
  # This is to assure a single transaction.
  def call(%{"from" => from_id, "to" => to_id, "value" => value}) do
    withdraw_params = build_params(from_id, value)
    deposit_params = build_params(to_id, value)
    Multi.new()
    |> Multi.merge(fn _changes -> Operation.call(withdraw_params, :withdraw) end)
    |> Multi.merge(fn _changes -> Operation.call(deposit_params, :deposit) end)
    |> run_transaction()

  end

  # This is to crate the expected map to populate Operation.call.
  defp build_params(id, value), do: %{"id" => id, "value" => value}

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

And update operation.ex to match the following.

`operation_name = account_operation_name(operation)` before `Multi.new()`

`|>Multi.run(:update_balance, fn repo, %{account: account} ->` changes to 

`Multi.run(operation, fn repo, changes -> account = Map.get(changes, operation_name)` to avoid ecto conflicts by having 2 transactions to merge with the same labels.

Create the private function at the end of the file: 
```elixir
  #Convert to an independent atom to avoid Ecto merge conflict
  defp account_operation_name(operation) do
    "account_#{Atom.to_string(operation)}" |> String.to_atom()
  end
```

Now update operation.ex to match the following.
`    |>Multi.run(:account, fn repo, _changes -> get_account(repo, id) end)` changes to 
`    |>Multi.run(account_operation_name(operation), fn repo, _changes -> get_account(repo, id) end)` to avoid ecto conflicts by having 2 transactions to merge with the same labels.

Now go to the iex and test it.
`iex()>recompile`

First, find to valid accounts UUIDs:
`iex()> Rocketpay.Repo.all(Rocketpay.Account)`

Now run the transfer transaction
`iex()>Rocketpay.Accounts.Transaction.call(%{"from" => "2eeb172c-a881-4463-b949-a44d1944be81", "to" => "f4035d76-2870-4b62-a36b-9480284e44df", "value" => "1.50"})`

It will raise an error, as run_transaction function still sends :update_balance but expects something else. 
Lets update the line `{:ok, %{update_balance: account}} -> {:ok, account}` to `{:ok, %{update_balance: account}} -> {:ok, account}` on the transaction.ex file.

Rerun the transfer transaction again. A structure having deposit and withdraw should show up.
```elixir
...
},
  withdraw: %Rocketpay.Account{
    __meta__: #Ecto.Schema.Metadata<:loaded, "accounts">,
    balance: #Decimal<212.00>,
    id: "2eeb172c-a881-4463-b949-a44d1944be81",
    inserted_at: ~N[2021-02-26 03:44:20],
    updated_at: ~N[2021-02-27 21:48:52],
    user: #Ecto.Association.NotLoaded<association :user is not loaded>,
    user_id: "5d467b4d-db5b-4b0e-b584-7e0db21f2853"
  }
...
```

Now update the transaction.ex file to map it correctly. Make the same line be like:
```elixir
      {:ok, %{deposit: to_account, withdraw: from_account}} ->
        {:ok, %{to_account: to_account, from_account: from_account}}

```

Try `iex()>recompile` and rund again `iex()>Rocketpay.Accounts.Transaction.call(%{"from" => "2eeb172c-a881-4463-b949-a44d1944be81", "to" => "f4035d76-2870-4b62-a36b-9480284e44df", "value" => "1.50"})`

It should work.

Before running Insomnia/ Postman, update the `deposit.ex` line to have `{:ok, %{update_balance: account}} -> {:ok, account}` to `{:ok, %{account_deposit: account}} -> {:ok, account}`

Do the same to the file `withdraw.ex`: `{:ok, %{update_balance: account}} -> {:ok, account}` to `{:ok, %{account_withdraw: account}} -> {:ok, account}`

Now run the server `mix phx.server` and run Postman/Insomnia POST deposit endpoint and it should work.
`http://localhost:4000/api/accounts/2eeb172c-a881-4463-b949-a44d1944be81/deposit`


## Create the Transaction endpoint

Lets practice by create a new endpoint in router.ex

`post "/accounts/transaction", AccountsController, :transaction`

Create the following function on the `lib/rocketpay_web/controllers/accounts_controller.ex` file.

```elixir
  def transaction(conn, params) do
    with {:ok, %{} = transaction} <- Rocketpay.transaction(params) do
      conn
      |> put_status(:ok) # http 201
      |> render("transaction.json", transaction: transaction)
      end
  end
```
Go to the facade file `lib.rocketpay.ex` and add the following lines:

Alias: `alias Rocketpay.Accounts.{Deposit, Transaction, Withdraw}`

`defdelegate transaction(params), to: Transaction, as: :call`

Open the file `lib/rocketpay_web/views/accounts_view.ex` and add the following function.

```elixir
  def render("transaction.json", %{transaction: %{to_account: to_account, from_account: from_account}}) do
    %{
      message: "Transaction done succesfully",
        transaction: %{
          from_account: %{
            id: from_account.id,
            balance: from_account.balance
          },
          to_account: %{
            id: to_account.id,
            balance: to_account.balance
          }
      }
    }
  end
```

Now the POST endpoint `http://localhost:4000/api/accounts/transaction` with the JSON file 
```json
{
    "value":"5.5",
    "from":"f4035d76-2870-4b62-a36b-9480284e44df",
    "to":"84e95b30-d3a1-4c48-abe2-cc322bac51c4"
}
```
Should work.

## Creating the Transaction struct for better code organization

Structs will help the API return standardized data. 

Create the file `lib/rocketpay/accounts/transactions/response.ex` . The folder `transactions` must be created.

```elixir
defmodule Rocketpay.Accounts.Transaction.Response do

  defstruct [:from_account, :to_account]

end
```

Go to iex and try the following:

```elixir
recompile
alias Rocketpay.Accounts.Transaction.Response, as: TransactionResponse
%TransactionResponse{}
```
The struct returns: `%Rocketpay.Accounts.Transaction.Response{from_account: nil, to_account: nil}`

Update the response.ex file to be like the following.

```elixir
defmodule Rocketpay.Accounts.Transaction.Response do

  alias Rocketpay.Account

  defstruct [:from_account, :to_account]

  # It will return the accounts within the structure.
  # __MODULE__ has the defmodule value in it.
  def build(%Account{} = from_account, %Account{} = to_account) do
    %__MODULE__{
      from_account: from_account,
      to_account: to_account
    }
  end
end
```

Edit the `/lib/rockepay/accounts/transaction.ex` file. 

Add the alias for the created module above. `  alias Rocketpay.Accounts.Transaction.Response, as: TransactionResponse`

Replace the line `{:ok, %{to_account: to_account, from_account: from_account}}` by `{:ok, TransactionResponse.build(from_account, to_account)}`

Open the `lib/rocketpay_web/controllers/accounts_controller.ex` file and add the alias above: `alias Rocketpay.Accounts.Transaction.Response, as: TransactionResponse`

Get to the file `lib/rocketpay_web/views/accounts_controller.ex` and add the same alias `alias Rocketpay.Accounts.Transaction.Response, as: TransactionResponse`

Update the `render` function header to have `TransactionResponse` be 
`  def render("transaction.json", %{transaction: %TransactionResponse{to_account: to_account, from_account: from_account}}) do`

Now you can run the endpoint again. It should work. 

This is the end of part 4.
