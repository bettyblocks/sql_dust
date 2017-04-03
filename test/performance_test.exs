defmodule PerformanceTest do
  @moduledoc false
use ExUnit.Case
import Ecto.SqlDust
import ExProf.Macro
  @test %SqlDust{adapter: nil, from: "Address", group_by: nil, join_on: nil, limit: 1,
         offset: nil, order_by: ["id ASC"],
         schema: %{Address: %{table_name: "addresses"},
           AwesomeModel: %{table_name: "awesome_models"},
           Role: %{:table_name => "roles",
             "users" => %{association_foreign_key: "user_id",
               association_primary_key: "id", bridge_table: "roles_users",
               cardinality: :has_and_belongs_to_many, foreign_key: "role_id",
               primary_key: "id", resource: "User"}},
           User: %{:table_name => "users",
             "locale" => %{cardinality: :belongs_to, foreign_key: "locale_id",
               table_name: "user_locale_list"},
             "roles" => %{association_foreign_key: "role_id",
               association_primary_key: "id", bridge_table: "roles_users",
               cardinality: :has_and_belongs_to_many, foreign_key: "user_id",
               primary_key: "id", resource: "Role"}}},
         select: ["test12315 AS test12315", "test12327 AS test12327",
          "test12312 AS test12312", "test12376 AS test12376", "test12310 AS test12310",
          "test12323 AS test12323", "test12350 AS test12350", "test12359 AS test12359",
          "test12360 AS test12360", "test12356 AS test12356", "test1239 AS test1239",
          "test12345 AS test12345", "test12335 AS test12335", "test12333 AS test12333",
          "test12366 AS test12366", "test12354 AS test12354", "test12378 AS test12378",
          "test12313 AS test12313", "street AS street", "test12328 AS test12328",
          "test12321 AS test12321", "test12373 AS test12373", "test12322 AS test12322",
          "test12318 AS test12318", "test12332 AS test12332", "test12361 AS test12361",
          "test12331 AS test12331", "test12383 AS test12383", "test12348 AS test12348",
          "test12347 AS test12347", "updated_at AS updated_at",
          "test12369 AS test12369", "test12362 AS test12362", "test12338 AS test12338",
          "test12381 AS test12381", "test1238 AS test1238", "created_at AS created_at",
          "test12330 AS test12330", "test12342 AS test12342", "test12351 AS test12351",
          "test12367 AS test12367", "test12315 AS test12315", "test12327 AS test12327",
          "test12312 AS test12312", "test12376 AS test12376", "test12310 AS test12310",
          "test12323 AS test12323", "test12350 AS test12350", "test12359 AS test12359",
          "test12360 AS test12360", "test12356 AS test12356", "test1239 AS test1239",
          "test12345 AS test12345", "test12335 AS test12335", "test12333 AS test12333",
          "test12366 AS test12366", "test12354 AS test12354", "test12378 AS test12378",
          "test12313 AS test12313", "street AS street", "test12328 AS test12328",
          "test12321 AS test12321", "test12373 AS test12373", "test12322 AS test12322",
          "test12318 AS test12318", "test12332 AS test12332", "test12361 AS test12361",
          "test12331 AS test12331", "test12383 AS test12383", "test12348 AS test12348",
          "test12347 AS test12347", "updated_at AS updated_at",
          "test12369 AS test12369", "test12362 AS test12362", "test12338 AS test12338",
          "test12381 AS test12381", "test1238 AS test1238", "created_at AS created_at",
          "test12330 AS test12330", "test12342 AS test12342", "test12351 AS test12351",
          "test12367 AS test12367","test12315 AS test12315", "test12327 AS test12327",
           "test12312 AS test12312", "test12376 AS test12376", "test12310 AS test12310",
           "test12323 AS test12323", "test12350 AS test12350", "test12359 AS test12359",
           "test12360 AS test12360", "test12356 AS test12356", "test1239 AS test1239",
           "test12345 AS test12345", "test12335 AS test12335", "test12333 AS test12333",
           "test12366 AS test12366", "test12354 AS test12354", "test12378 AS test12378",
           "test12313 AS test12313", "street AS street", "test12328 AS test12328",
           "test12321 AS test12321", "test12373 AS test12373", "test12322 AS test12322",
           "test12318 AS test12318", "test12332 AS test12332", "test12361 AS test12361",
           "test12331 AS test12331", "test12383 AS test12383", "test12348 AS test12348",
           "test12347 AS test12347", "updated_at AS updated_at",
           "test12369 AS test12369", "test12362 AS test12362", "test12338 AS test12338",
           "test12381 AS test12381", "test1238 AS test1238", "created_at AS created_at",
           "test12330 AS test12330", "test12342 AS test12342", "test12351 AS test12351",
           "test12367 AS test12367","test12315 AS test12315", "test12327 AS test12327",
          "test12312 AS test12312", "test12376 AS test12376", "test12310 AS test12310",
          "test12323 AS test12323", "test12350 AS test12350", "test12359 AS test12359",
          "test12360 AS test12360", "test12356 AS test12356", "test1239 AS test1239",
          "test12345 AS test12345", "test12335 AS test12335", "test12333 AS test12333",
          "test12366 AS test12366", "test12354 AS test12354", "test12378 AS test12378",
          "test12313 AS test12313", "street AS street", "test12328 AS test12328",
          "test12321 AS test12321", "test12373 AS test12373", "test12322 AS test12322",
          "test12318 AS test12318", "test12332 AS test12332", "test12361 AS test12361",
          "test12331 AS test12331", "test12383 AS test12383", "test12348 AS test12348",
          "test12347 AS test12347", "updated_at AS updated_at",
          "test12369 AS test12369", "test12362 AS test12362", "test12338 AS test12338",
          "test12381 AS test12381", "test1238 AS test1238", "created_at AS created_at",
          "test12330 AS test12330", "test12342 AS test12342", "test12351 AS test12351",
          "test12367 AS test12367","test12315 AS test12315", "test12327 AS test12327",
         "test12312 AS test12312", "test12376 AS test12376", "test12310 AS test12310",
         "test12323 AS test12323", "test12350 AS test12350", "test12359 AS test12359",
         "test12360 AS test12360", "test12356 AS test12356", "test1239 AS test1239",
         "test12345 AS test12345", "test12335 AS test12335", "test12333 AS test12333",
         "test12366 AS test12366", "test12354 AS test12354", "test12378 AS test12378",
         "test12313 AS test12313", "street AS street", "test12328 AS test12328",
         "test12321 AS test12321", "test12373 AS test12373", "test12322 AS test12322",
         "test12318 AS test12318", "test12332 AS test12332", "test12361 AS test12361",
         "test12331 AS test12331", "test12383 AS test12383", "test12348 AS test12348",
         "test12347 AS test12347", "updated_at AS updated_at",
         "test12369 AS test12369", "test12362 AS test12362", "test12338 AS test12338",
         "test12381 AS test12381", "test1238 AS test1238", "created_at AS created_at",
         "test12330 AS test12330", "test12342 AS test12342", "test12351 AS test12351",
         "test12367 AS test12367"], unique: true,
         variables: %{scope: "NULL", scope_value: "NULL", var3: "1"},
         where: ["(id = <<var3>>)"]}
  test "big select test" do
    to_sql(@test)
  end
end
