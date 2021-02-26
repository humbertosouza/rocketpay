defmodule Rocketpay.Users.Create do

  # References:
  # 1 - https://www.youtube.com/watch?v=eHYQcKe1WQ4
  # 2 - https://www.youtube.com/watch?v=69NxjBQNTIk
  # 3 - https://www.youtube.com/watch?v=ay6rlFXfI8g
  # 4 - https://www.youtube.com/watch?v=5fwonPrjQN8
  # 5 - https://www.youtube.com/watch?v=_5KYB0hbRAI

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
