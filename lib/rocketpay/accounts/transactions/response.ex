defmodule Rocketpay.Accounts.Transaction.Response do

  alias Rocketpay.Account

  defstruct [:from_account, :to_account]

  # It will return the accounts within the structure.
  # __MODULE__  has the defmodule value in it.
  def build(%Account{} = from_account, %Account{} = to_account) do
    %__MODULE__{
      from_account: from_account,
      to_account: to_account
    }
  end

end
