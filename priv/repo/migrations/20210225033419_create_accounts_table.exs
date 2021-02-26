defmodule Rocketpay.Repo.Migrations.CreateAccountsTable do
  use Ecto.Migration

  def change do
    create table :accounts do
      add :balance, :decimal # for monetary values, ecto uses this DECIMAL type
      add :user_id, references(:users, type: :binary_id)

      timestamps()

    end

    # Constraints brings part of the logic to the DB>
    # This is to assure the user will not be with negative balance
    create constraint(:accounts, :balance_must_be_positive_or_zero, check: "balance >= 0")

  end
end
