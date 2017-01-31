## SqlDust CHANGELOG

### Version 0.3.9 (January 31, 2017)

* Ignore empty WHERE statements
* Allow Ecto 2

### Version 0.3.8 (November 22, 2016)

* Handle columns ending with integers properly (e.q. `users`.`address1`) (thanks @Wijnand)

### Version 0.3.7 (November 21, 2016)

* Handle columns starting with integers properly (e.q. `users`.`1st_address`) (thanks @danielwillemse)

### Version 0.3.6 (October 12, 2016)

* Being able to tackle extreme naming of tables and columns (e.g. `this is some.weird.table_name`) (thanks @nulian)

### Version 0.3.5 (July 28, 2016)

* No longer appending items to a list using `List.insert_at(-1, ...)` because that has a high performance impact (thanks @nulian)

### Version 0.3.4 (May 24, 2016)

* Supporting specifying to ensure unique base records when composing queries
* Added option :unique which instructs SqlDust to ensure always getting unique base records when encountering collection joins

### Version 0.3.3 (May 11, 2016)

* Add quoting to table names so queries wont break because of reserved words

### Version 0.3.2 (March 22, 2016)

* Adding deep merge for nil and false values

### Version 0.3.1 (March 14, 2016)

* Adding word boundaries when numerizing word patterns

### Version 0.3.0 (March 13, 2016)

* Returning corresponding variable keys within resulting tuple (only when having passed options[:variables] of course)

### Version 0.2.2 (March 13, 2016)

* Being able to use variables containing nested maps (e.g. "<<user.first_name>>")

### Version 0.2.1 (March 11, 2016)

* Added #variables/1 and #variables/2 for use when composing queries
* Also quoting column names

### Version 0.2.0 (March 11, 2016)

* Replaced `macro` with `cardinality`
* Returning a tuple containing SQL along with values (for tackling SQL injection)
* Correctly taking SQL injection measurements when composing queries

### Version 0.1.11 (March 10, 2016)

* Being able to specify additional join conditions using :join_on / #join_on
* Being able to specify additional join conditions within the schema

### Version 0.1.10 (March 10, 2016)

* Corrected has_one join specification

### Version 0.1.9 (March 9, 2016)

* Being able to override the table name of an association

### Version 0.1.8 (March 9, 2016)

* Fixed missing :offset statement when specifying during query composing

### Version 0.1.7 (March 4, 2016)

* Tackled error when having `''` within WHERE statements (thanks @nulian)
* Supporting has_one associations

### Version 0.1.6 (February 29, 2016)

* Respecting booleans

### Version 0.1.5 (February 16, 2016)

* Respecting preserved word NULL

### Version 0.1.4 (February 16, 2016)

* Quoting SELECT statement aliases
* Supporting paths as SELECT statement aliases

### Version 0.1.3 (February 14, 2016)

* Being able to define OFFSET
* Made Ecto dependency optional

### Version 0.1.2 (February 9, 2016)

* Downcasing base table alias

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
