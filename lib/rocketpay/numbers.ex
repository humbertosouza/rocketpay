defmodule Rocketpay.Numbers do
  def sum_from_file(filename) do
    # Classic way
    #file = File.read("#{filename}.csv") #interpolation takes "" and #{}
    #handle_file(file)

    # Using Pipe operator
    "#{filename}.csv"
    |> File.read()
    |> handle_file()

    #more arguments need more matchings

  end

  #defp handle_file({:ok, file}), do: file #pattern matching can be used in the function definition. , : sugar (single line)
  #from minute 40:
  #defp handle_file({:ok, result}) do
  #  result = String.split(result, ",")
  #  result = Enum.map(result, fn number -> String.to_integer(number) end)
  #  result = Enum.sum(result)
  #  result
  #end
  defp handle_file({:ok, result}) do
    #functional language... it is like a factory sequencing.
    result =
      result
      |> String.split(",") #result is passed above
      |> Enum.map(fn number -> String.to_integer(number) end ) #result is passed before fn ...
      #|> Stram.map(fn number -> String.to_integer(number) end ) # lazy operator ...
                                                                 # ... will only process when  Enum.Sum() ONLY ONCE
      |> Enum.sum() # result is implicitly inside

      {:ok, %{result: result}}

    end


  defp handle_file({:error, _reason}), do: {:error, %{message: "Invalid File!"}} #must be a 2-element tupple


end
