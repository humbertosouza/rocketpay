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

  #Using patter matching, it will check the third parameter if it is "deposito". If so, add.
  defp handle_cast({:ok, value}, balance, :deposito), do: Decimal.add(balance, value) #inverted when adding
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
