defmodule Rocketpay.Accounts.Transaction do
  alias Ecto.Multi
  alias Rocketpay.Repo
  alias Rocketpay.Accounts.Operation
  alias Rocketpay.Accounts.Transaction.Response, as: TransactionResponse
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
      {:ok, %{deposit: to_account, withdraw: from_account}} ->
        {:ok, TransactionResponse.build(from_account, to_account)}
    end
  end

end
