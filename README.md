# SqlDust [![Build Status](https://travis-ci.org/archan937/sql_dust.svg?branch=master)](https://travis-ci.org/archan937/sql_dust) [![Inline docs](http://inch-ci.org/github/archan937/sql_dust.svg)](http://inch-ci.org/github/archan937/sql_dust)

Generate (complex) SQL queries using magical Elixir SqlDust

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add sql_dust to your list of dependencies in `mix.exs`:

        def deps do
          [{:sql_dust, "~> 0.0.1"}]
        end

  2. Ensure sql_dust is started before your application:

        def application do
          [applications: [:sql_dust]]
        end
