# Elixir - JSON backend payment app

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

`    get "/:filename", WelcomeController, :index  #this adds a route under /api`







  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server`



Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Useful links

Configure Postgres in Ubuntu 20
https://www.tecmint.com/install-postgresql-and-pgadmin-in-ubuntu/
https://www.tecmint.com/backup-and-restore-postgresql-database/


