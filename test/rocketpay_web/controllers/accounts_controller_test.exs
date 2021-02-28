defmodule RocketpayWeb.AccountsControllerTest do

  # This will help because we have controller functionalities to be used in this test.
  use RocketpayWeb.ConnCase, async: true

  alias Rocketpay.{Account, User}

  # it is deposit/2 as it expects the connection and the paramenters
  describe "deposit/2" do
    # User creation will require a setup
    setup %{conn: conn} do
      params = %{
        name: "Humberto",
        password: "nan1234",
        nickname: "gostoso",
        email: "test@email.com",
        age: 27
      }

      {:ok, %User{account: %Account{id: account_id}}} = Rocketpay.create_user(params)

      #Here the authentication needs to be set in order to run the POST commands adequately
      # for the expected tests. Fill the line below as the result of the
      # previous result of the basic authentication `iex()>Base.encode64("banana:nanica123")`
      # The put_req_header will add the field/value to the header.
      conn = put_req_header(conn, "authorization", "Basic YmFuYW5hOm5hbmljYTEyMw==" )

      # The end of a setup a tuple having :ok and key/value are always required
      {:ok, conn: conn, account_id: account_id}
    end

    test "when all params are valid, execute the deposit", %{conn: conn, account_id: account_id} do
      params = %{"value" => "50.00"}

      # Use the helper from the ConnCase controller to find the account route
      # Post calls the same post as Postman/Insomnia
      # The format is Routes.accounts_path(connection, action(deposit), id (part of the URL), parameters)
      # When using json_response in tests for encoding the response, we need to provide the valid
      #  match verb(:ok) because the test will validate it.
      # json_response(:ok) will not work because the transaction is not authenticated.
      response =
        conn
        |> post(Routes.accounts_path(conn, :deposit, account_id, params))
        |> json_response(:ok)

      # For testing the output, do this first
      # assert  response == banana
      # Copy the values from the test results

      # For the real test, we cannot use == but the pattern match because the id varies every time
      # We need to ignore the id by making _id

      # HOWEVER, the code below expects the balance to change, but it came zero
      assert %{
                "account" => %{"balance" => "50.00", "id" => _id },
                "message" => "Balance changed succesfully"
              } = response

      # You may debug the code to find where the issue is by using IO.inspect() within the pipes
      # |> ...
      # |> IO.inspect()
      # |> ...

      # the problem was in the deposit.ex. Check it by changing the `defp run_transaction(multi) do
      # Check the comments there for more details.
    end

    test "when there are invalid params, returns an error", %{conn: conn, account_id: account_id} do
      params = %{"value" => "banana"}

      response =
        conn
        |> post(Routes.accounts_path(conn, :deposit, account_id, params))
        |> json_response(:bad_request)

      expected_value = %{
        "message" => "Invalid operation value!"
      }

      assert  expected_value == response
    end
  end
end
