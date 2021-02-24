# Elixir - JSON backend payment app - Part 2

## Ecto - Database data for Phoenix and Elixir

It is a particular tool comparing to other available frameworks.

Make sure you run `$mix ecto.create` on your application folder e.g. ~/rocketpay

Then use the command `$mix ecto.gen.migration create_user_table` where create_user_table will create a file, having the timestamp. The database tables may change in the future.
By using the command above the app will manage what migrations it has already run and the ones that are pending.

Data will be in the priv/repo/migrations/<timestamp>_create_user_table.

A migration is a file containing commands that will be executed in the DB.

Check the file snippet below for more details.

```javascript
  # Change allows to change to reflect what is created. It is also allow rollbacks
  def change do
    create table :users do
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

```
Note that the add:id, :integer or :id, :binary_id is implicitly created.

Go to the command prompt and type

`$mix ecto.migrate`

Then go to the lib/rocketpay and create the file user.ex

Go to the lib/Rocketpay/repo.ex, which takes care of the database module;

Go to the config.exs and add the following lines after the config instruction having the signing salt:

```javascript
config :rocketpay, Rocketpay.Repo,
  migration_primary_key: [type: :binary_id],
  migration_foreing_key: [type: :binary_id]
```

Go back to the command prompt, and run `$mix ecto.drop` , which will delete the created database.

Then run again `$mix ecto.create` and `$mix ecto.migrate` again to have the UUIDs as defaults.

The content of the file user.ex should be something like
```javascript
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

```

Then create inside lib/rocketpay/users create the file `create.ex`

Make sure the file looks like the following.

```javascript
defmodule Rocketpay.Users.Create do
   alias Rocketpay.{Repo, User} #creating 2 aliases at same time

   def call(params) do
    params
    |> User.changeset()
    |>Repo.insert()
   end
end

```

Go to the root folder called "rocketpay.ex", delete the documentation and make it as following

```javascript
defmodule Rocketpay do
  alias Rocketpay.Users.Create, as: UserCreate

  defdelegate create_user(params), to: UserCreate, as: :call
end
```

It will save the chain of pipes for the iex(x)> module.
You can test it in the iex:

`iex(1)>params = %{name: "Humberto3", password: "123456", nickname: "beto3", age: 41, email: "humberto3@ited.com.br"}`

`iex(2)>Bumblepay.create_user(params) `

Now it is time to create routes.

Go to therocketpay_web/route.ex and add the following after the existing get entry.

`post "/users", UsersController, :create`

Copy the existing welcome_controller.ex and add the copied file to the same folder 
lib/rocketpay_web/controllers/users_controller.ex

Update the code according to the following.

```javascript
defmodule RocketpayWeb.UsersController do
  use RocketpayWeb, :controller

  alias Rocketpay.User

  def create(conn, params) do # Action
    params
    |> Rocketpay.create_user()
    |> handle_response(conn) #conn is the second parameter!

  end

  defp handle_response({:ok, %User{} = user}, conn) do
    conn
    |> put_status(:created) # http 201
    |> render("create.json", user: user) #it will call a view. Create a view with same name of the controller
  end

  defp handle_response({:error, result}, conn) do
   conn
    |> put_status(:bad_request)
    |> put_view(RocketpayWeb.ErrorView)
    |> render("400.json", result: result)
  end

end
```
 Then create a view under lib/rocketpay_web/views/users_view.ex

 The content will look like as follows:

 ```javascript
 defmodule RocketpayWeb.UsersView do #same name from the controller, so it renders correctly
  alias Rocketpay.User
  def render("create.json", %{user: %User{id: id, name: name, nickname: nickname}}) do
    %{
      message: "User Created",
      user: %{
        id: id,
        name: name,
        nickname: nickname
      }
    }

  end
end
 ```

Activate the server using `$mix phx.server`

Go to Insomnia or Postman, and create a POST pointing to http://localhost:4000/api/users
Body JSON
{
    "name":"Joao",
    "nickname": "john",
    "age": 27,
    "email": "joao@test.com.br",
    "password": "123456"
}







## Useful links

Configure Postgres in Ubuntu 20

https://www.tecmint.com/install-postgresql-and-pgadmin-in-ubuntu/

https://www.tecmint.com/backup-and-restore-postgresql-database/


