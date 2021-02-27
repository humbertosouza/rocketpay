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

23:45



