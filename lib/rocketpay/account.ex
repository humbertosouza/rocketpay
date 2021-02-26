defmodule Rocketpay.Account do
  # Map the schema. Schema is the closest thing to the model, but it is only data mapping here.any()
  use Ecto.Schema
  import Ecto.Changeset

  alias Rocketpay.User

  @primary_key {:id, :binary_id, autogenerate: true} #Binary_ID means UUID.
  @foreign_key_type :binary_id#Binary_ID means UUID.

  @required_params [:balance, :user_id] #mandatory fields
  # :value are atoms - string constants

  schema "accounts" do
    field :balance, :decimal  #For monetary values
    belongs_to :user, User

    # means that it belongs to the user schema
    timestamps() #Must be present as the fields are mandatories
  end

  #Changeset maps and validate data.
  # struct module has moved to the function parameters. It can be a empty struct OR a struct that have value
  # \\ indicates a DEFAULT parameters, that is the empty struct
  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, @required_params) #cast convert the struct to a changeset (check with IO.Inspect())
    |> validate_required(@required_params) #check all required params
    |> check_constraint(:balance, name: :balance_must_be_positive_or_zero)

  end



end
