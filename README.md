Regal
=====
SQL Relational algebra builder

About
-----
Regal (RElational ALgebra) is a library for generating SQL programatically,
and is intended to be used as the SQL generator for ORMs (although it can
be used on its own).

Usage
-----

#### `Table`:
The main API exposed by Regal. A `Table` is initialized by supplying a
table name (`string`), and a schema
```d
  auto users = new regal.Table!(
    "users",
    int,    "id",
    string, "name",
    int,    "created_at",
    int,    "updated_at");
```

