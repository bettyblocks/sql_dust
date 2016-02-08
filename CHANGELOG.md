## SqlDust CHANGELOG

### Version 0.1.1 (February 8, 2016)

* Being able to compose Ecto based queries using `Ecto.SqlDust` (w00t! ^^)
* Being able to use resource names when composing queries
* Added `:adapter` option to determine the quotation mark (backtick for MySQL and double quote for Postgres)
* Extracted `SqlDust.Query` to `SqlDust.Utils.ComposeUtils`
* Changed `%SqlDust.QueryDust{}` into `%SqlDust{}`
* Using Ecto v1.1.3

### Version 0.1.0 (February 6, 2016)

* Added ability for composable queries (thanks to [Justin Workman](https://github.com/xtagon) for the request)
* Moved utility modules to `lib/sql_dust/utils`

### Version 0.0.1 (February 4, 2016)

* Initial release
