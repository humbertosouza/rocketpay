defmodule RocketpayWeb.UsersViewTest do #same name from the controller, so it renders correctly
  # Uses the same ConnCase module
  use RocketpayWeb.ConnCase, async: true

  # This make the 'render' function available
  import Phoenix.View

  alias Rocketpay.{Account, User}
  alias RocketpayWeb.UsersView

  # The test below has no describe because it is a single function test module, for rendering
  #  so there is no need for the description in this view, even though it could be done.
  # Phoenix itself follows this standard - check the file error_view_test.exs file in the same folder.

  # Lets create the user
  # *** The view is called only in case of success ***
  # Copy the parameters from the create_test.exs
  test "renders create.json" do
    params = %{
      name: "Humberto",
      password: "nan1234",
      nickname: "gostoso",
      email: "test@email.com",
      age: 27
    }

    {:ok, %User{id: user_id, account: %Account{id: account_id}} = user} = Rocketpay.create_user(params)

    response = render(UsersView, "create.json", user: user )

    # this is to fail the test and create the correct response.
    #assert "banana" == response

    # As some data is variable, copy the `mix test` output of this test and past it here.
    #assert %{message: "User Created", user: %{account: %{balance: #Decimal<0.00>, id: "37231f7a-54a9-4337-ae25-3e311d18cf1d"}, id: "c6a50e9f-629a-4be9-a67b-87aa600bfb50", name: "Humberto", nickname: "gostoso"}} = response

    #Change #Decimal<"0.00"> to Decimal.new("0.00")
    # it will also use the account_id above and the user_id above
    expected_response = %{message: "User Created",
      user:
        %{account:
          %{balance:
              Decimal.new("0.00"),
              id: account_id
          },
          id: user_id,
          name: "Humberto",
          nickname: "gostoso"
        }
      }

    # In this case, we can use  the  == because we created the response and all required variables BEFORE
    #  this function is invoked.
    assert expected_response == response
  end
end
