defmodule Rocketpay.Accounts.Operation do
  alias Ecto.Multi

  alias Rocketpay.{Account, Repo}

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

  defp handle_cast({:ok, value}, balance), do: Decimal.sub(balance, value) #inverted when adding
  defp handle_cast(:error, _balance), do: {:error, "Invalid deposit value!"}



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
