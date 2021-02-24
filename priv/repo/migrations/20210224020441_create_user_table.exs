defmodule Rocketpay.Repo.Migrations.CreateUserTable do
  use Ecto.Migration

  # Change allows to change to reflect what is created. It is also allow rollbacks
  def change do
    create table :users do
      # :id, :integer , or :id :binary_id (UUID)
      add :name, :string
      add :age, :integer
      add :email, :string
      add :password_hash, :string
      add :nickname, :string # the money is transferred between users via nickname

      timestamps() # it adds automatically Created_at and updated_at

    end

    create unique_index(:users, [:email]) # This will not allow repeated emails
    create unique_index(:users, [:nickname]) # nickname must be unique as well.

  end

  # What can be done using the migration
  #def up do
  #end

  # What must be done during the rollback
  #def down do
  #end


end
