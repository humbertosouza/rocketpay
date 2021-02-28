defmodule Rocketpay.Accounts.Operation do
  alias Ecto.Multi

  alias Rocketpay.{Account, Repo}

  # We do not need to use "run transaction"
  # Update update_balance to have repo, account, value and operation.
  def call(%{"id" => id, "value" => value}, operation) do
    operation_name = account_operation_name(operation)
    Multi.new()
    |> Multi.run(operation_name, fn repo, _changes -> get_account(repo, id) end)
    #|> Multi.run(operation, fn repo, %{account: account} -> # Old fashion
    |> Multi.run(operation, fn repo, changes -> account = Map.get(changes, operation_name)
      update_balance(repo, account, value, operation)
    end)
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

  #Convert to an independent atom to avoid Ecto merge conflict
  defp account_operation_name(operation) do
    "account_#{Atom.to_string(operation)}" |> String.to_atom()
  end


end
