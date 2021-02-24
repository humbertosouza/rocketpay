defmodule Rocketpay.Users.Create do
   alias Rocketpay.{Repo, User} #creating 2 aliases at same time

   def call(params) do
    params
    |> User.changeset()
    |>Repo.insert()
   end
end
