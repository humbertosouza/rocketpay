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
      #{}:ok, %{update_balance: account}} -> {:ok, account} # Replaced by the line below.

      # A bug was found below. We can map it by running the following during tests
      # original: {:ok, %{account_deposit: account}} -> {:ok, account}
      # debug version:
      # {:ok, %{account_deposit: account} = map} ->
      #  IO.inspect(map)
      #  {:ok, account}

      # The same happened to the withdraw.

      # correct version
      {:ok, %{deposit: account}} -> {:ok, account}
    end
  end

end
