# Elixir - JSON backend payment app - Part 1

To start your Phoenix server.
`$mix archive.install hex phx_new 1.5.7`

Prepare Rocketpay
`$mix phx.new rocketpay --no-webpack --no-html`
No webpack and no html are required as only a JSON REST service will be established for this project

`$cd rocketpay`

Add or adjust the Postgres databases for rocketpay_test and rocketpay_dev
`$sudo -u postgres psql`

`postgres=#ALTER USER postgres WITH PASSWORD 'xxxxxx';`

`postgres=#CREATE DATABASE rocketpay_dev;`

`postgres=#CREATE DATABASE rocketpay_test;`

`postgres=#GRANT ALL PRIVILEGES ON DATABASE rocketpay_dev TO postgres;`

`postgres=#GRANT ALL PRIVILEGES ON DATABASE rocketpay_test TO postgres;`

`postgres=#\q`

Open VS Code

`$code .`

After adding and adjusting the DB

`$mix ecto.setup`

Get dependencies for Elixir (Online)

`$mix deps.get`

Create all lint configuration for the application - All confs will be at .credo.exs

`mix credo gen.config`

Open the file .credo.exs and update the "Readability.ModuleDoc" from [ ] to false. We will not generate documentation about the code.

`        {Credo.Check.Readability.ModuleDoc, false},`

Go to the rocketpay_web\router.ex, add after  `pipe_through :api` (line 11)

`    get "/", WelcomeController, :index  #this adds a route under /api`

Create a file called "welcome_controller.ex under rocketpay_web\controllers
Note that Elixir is a functional language, so there are no classes. It has functions only.
The controller is a special function. what makes it special is the flag `RocketpayWeb, :controller`

The file content follows

```javascript
defmodule RocketpayWeb.WelcomeController do
  use RocketpayWeb, :controller


  def index(conn, _params) do
    text(conn, "Welcome to the Rocketpay API")
  end
end  
```

Another interesting point is that the function parameters starting with underscore are ignored by default. E.g. _params


## Running the application

  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

You should try http://localhost:4000/api for the first version of the welcome_controller;


## Creating Elixir functions


Create the file rocketpay\numbers.ex having the function sum_from_file(filename)

```javascript

defmodule Rocketpay.Numbers do
  def sum_from_file(filename) do
    # Classic way
    file = File.read("#{filename}.csv") #interpolation takes "" and #{}
    handle_file(file)
  end   

  defp handle_file({:ok, result}) do
    result = String.split(result, ",")
    result = Enum.map(result, fn number -> String.to_integer(number) end)
    result = Enum.sum(result)
    result
  end

```
Create the file numbers.csv on the project root. It's content should be:

`1,2,3,4,8,9,10`

#The Elixir command line interpreter

Let's call functions from the command prompt. 

`$iex`

For calling your application functions from the command prompt, use

`$iex -S mix`

Then

`iex(1)>Rocketpay.Numbers.sum_from_file("numbers")`

It should return the tupple {:ok,"1,2,3,4,8,9,10"}. If you call an invalid file name, it would return as following:

`iex(1)>Rocketpay.Numbers.sum_from_file("bananas")`

`{:error,:enoent}`

A tupple could be {1,2,"string",4}

In Elixir, the equal sign is NOT same as equality. It is assertion. It also performs pattern matching

E.g.
1 = x (OK)
2 = x (error - false)

While

x = 1 (OK)
x = 2 (OK)

For pattern matching, the number of elements must match

`iex(1)>{:ok, file} = Rocketpay.Numbers.sum_from_file("numbers")`

And it would return

`{:ok, "1,2,3,4,8,9,10"}`

`iex(2)>file`

`"1,2,3,4,8,9,10"`

`iex(3)>[a,b,c,d] = [1, 2, 3, 4]`

`iex(4)>a`

Would be 1, b = 2, c =3 and d = 4.

* The number of elements must match.

Like most languages, String.<tab> will show all available options for string.

For showing the help of a given function use

`h String.split`

## Enum x Streams

Streams do lazy load while Enum process imediately.

The Erlang VM is quite optmized so it would prepare a sequence of enums at once, optmizing the number of lists/variables created in memory

`Enum.map(lista, fn .. end) ` - The fn ... end represents an anonymous function.

`Enum.map(lista, fn number -> String.to_integer(number) end)` - For each number, create a list. it is 
immutable. In Elixir, data in memory never changes. 

`|> Enum.map(fn number -> String.to_integer(number) end )` It is processed ...`

`|> Stream.map(fn number -> String.to_integer(number) end)` lazy operator ...`

`|> Enum.sum()`  Here is where the Stream maps are processed at once

## Maps 

Maps are structures as found on other languages. Its use in Elixir follows:

`iex()>mapa = %{a: 1, b: 2, c: 3, d: 4}`

`iex()> Map.get(mapa, :b)`

Results 2

## Atoms

Atoms as largely used in Elixir.
Atoms are items similar to strings but they have a special function in Elixir.
They can be converted from one type to another.

```elixir
$iex
iex()>String.to_atom("agua")
:agua
iex()>operation = :test
iex()>"account_#{Atom.to_string(operation)}" |> String.to_atom()
:account_test
```

## Aliases

One's can use aliases for calling functions from both the code and the iex.

`iex(1)>alias Rocketpay.Numbers`

`iex(2)>Numbers.sum_from_file("banana")`


## Pipe Operators

It is possible to pass the parameters to the next function via pipe operators. It will be always the first parameter of the function.

iex(1)>"numbers" |> Rocketpay.Numbers.sum_from_file()

Example from the enhanced welcome_controller.ex file

```javascript
  def index(conn, %{"filename" => filename}) do 
        #This saves the pattern match into a variable filename.
        # in the iex, it uses string: value;
        # but in the controller file it uses "string => value 
    filename
    |> Numbers.sum_from_file()
    |> handle_response(conn) #conn is the second parameter!

  end

```

## Unit tests

Create the files following the controller name added by _test.exs. Tests are script files, so the "S" goes to the filename extension.

Create the `numbers_test.exs` under the folder test

```javascript

defmodule Rocketpay.NumbersTest do
  use ExUnit.Case

  alias Rocketpay.Numbers

  describe "sum_from_file/1" do #Test description
    test "When there is a condition" do
        
        response = function_to_test("value")
        expected_response = {:expected, response}
        assert response == expected_response
        
    end 

end  

```
At the prompt, run the commamd mix test

`$mix test` 

## Useful links

Configure Postgres in Ubuntu 20

https://www.tecmint.com/install-postgresql-and-pgadmin-in-ubuntu/

https://www.tecmint.com/backup-and-restore-postgresql-database/


