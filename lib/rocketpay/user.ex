defmodule Rocketpay.User do
  # Map the schema. Schema is the closest thing to the model, but it is only data mapping here.any()
  use Ecto.Schema
  import Ecto.Changeset

  alias Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true} #Binary_ID means UUID.

  @required_params [:name, :age, :email, :password, :nickname] #mandatory fields
  # :value are atoms - string constants

  schema "users" do
    field :name, :string
    field :age, :integer
    field :email, :string
    field :password, :string, virtual: true # this field is virtual
    field :password_hash, :string
    field :nickname, :string # the money is transferred between users via nickname

    timestamps() #Must be present as the fields are mandatories
  end

  #Changeset maps and validate data.
  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @required_params) #cast convert the struct to a changeset (check with IO.Inspect())
    |> validate_required(@required_params) #check all required params
    |> validate_length(:password, min: 6) # Runs specific validating functions
    |> validate_number(:age, greater_than_or_equal_to: 18)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint([:email])
    |> unique_constraint([:nickname])
    |> put_password_hash()
  end

  #Go to the command prompt and type $iex -S mix
  # iex(1)>alias Rocketpay.User
  # iex(2)>User.changeset(%{name: "Humberto", password: "123456", nickname: "beto", age: 41, email: "humberto@ited.com.br"})
  # Take out one field and check.
  # iex(3)>recompile
  # Check the struct in iex:
  # iex(4)>%User{}

  # Add a lib to the file mix.exs the lib {:bcrypt_elixir,"~> 2.0"} right after credo
  defp put_password_hash(%Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Bcrypt.add_hash(password))
  end

  defp put_password_hash(changeset), do: changeset

  # The Repo is the module who communicates with the database.
  #iex(10)>params = %{name: "Humberto", password: "123456", nickname: "beto", age: 41, email: "humberto@ited.com.br"}
  #iex(11)> params |> User.changeset() |> Rocketpay.Repo.insert()
  #Try to insert a blank schema
  #iex(12)>%{} |> User.changeset() |> Rocketpay.Repo.insert()

end
