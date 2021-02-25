defmodule RocketpayWeb.ErrorView do
  use RocketpayWeb, :view

  import Ecto.Changeset, only: [traverse_errors: 2]   # bring from module the function.
                                                      # Like Python, it allow you to call the function

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end

  alias Ecto.Changeset
  # def render("400.json", %{result: changeset}) do  # Matching the 400.json and the changesett
  def render("400.json", %{result: %Changeset{} = changeset}) do   # Even better, lets do the pattern matching so that
                                                     #  the function only matches with
    %{message: translate_errors(changeset)}
  end

  # Search in the documentation for traverse_errors
  defp translate_errors(changeset) do
    traverse_errors(changeset, fn {msg, opts} -> # same as Ecto.Changeset.traverse_errors
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end

end
