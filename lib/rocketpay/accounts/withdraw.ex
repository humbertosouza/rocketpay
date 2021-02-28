defmodule Rocketpay.Accounts.Withdraw do

  alias Rocketpay.Accounts.Operation
  alias Rocketpay.Repo

  # ** This has been refactored **
  # It is just an account update, however, the account may exist or not..

  # read id and value via pattern match
  def call(params) do
    params
    |> Operation.call(:withdraw)
    |> run_transaction()
  end

  #Now you can copy and adapt the run_transaction code from create.ex
  defp run_transaction(multi) do
    case Repo.transaction(multi) do
      {:error, _operation, reason, _changes} -> {:error, reason} #dont care the 2nd and 4th parameters
      # last transaction from multi is update_balance, as following
      #     |>Multi.run(:update_balance, fn repo, %{account: account} -> update_balance(repo, account, value) end)
      #{}:ok, %{update_balance: account}} -> {:ok, account} # Replaced by the line below.

      # Check the corrected bug comments on deposit.ex and the test accounts_controller_test.exs
      # bugged version
      #{:ok, %{account_withdraw: account}} -> {:ok, account}
      # Corrected version
      {:ok, %{withdraw: account}} -> {:ok, account}

    end
  end

end
