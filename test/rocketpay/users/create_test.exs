defmodule Rocketpay.Users.CreateTest do
  # Add Test to the end of the module name.any()
  # We are not using the ExUnit
  use Rocketpay.DataCase

  alias Rocketpay.User
  alias Rocketpay.Users.Create  # For testing

  describe "call/1" do
    test "When all params are valid, returns an user" do
      params =%{
        name: "Humberto",
        password: "nan1234",
        nickname: "gostoso",
        email: "test@email.com",
        age: 27
      }

      {:ok, %User{id: user_id}} = Create.call(params)
      # Check if it is in the data
      user = Repo.get(User, user_id)
      # the ^ means it is the PIN operator. If  there is no ^ the test would pass. But the PIN fix the value
      # it is using PIN and = . The ID is generated automatically, and the value will be a new value.
      # It will assure the reading before using it.
      assert %User{name:"Humberto", age: 27. id: ^user_id} = user

    end

    test "When there are invalid params, returns an error" do
      params =%{
        name: "Humberto",
        nickname: "gostoso",
        email: "test@email.com",
        age: 27
      }

      {:error, changeset} = Create.call(params)

      expected_response = %{
          age: ["Must be greater than or equal to 18"],
          password: ["Cant be blank"]
      }
      # the ^ means it is the PIN operator. If  there is no ^ the test would pass. But the PIN fix the value
      # it is using PIN and = . The ID is generated automatically, and the value will be a new value.
      # It will assure the reading before using it.
      assert errors_on(changeset) = expected_response
    end

  end

end
