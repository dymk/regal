Regal
=====
SQL relational algebra builder for D

About
-----
Regal (RElational ALgebra) is a dependency free library for generating SQL programatically,
and is intended to be used as the SQL generator for ORMs (although it can
be used on its own). The API is modeled after Ruby's [Arel](https://github.com/rails/arel),
and it attempts to provide analagous features.

Usage
-----

#### A quick introduction

`Table` is the main API exposed by Regal. A `Table` is initialized by supplying a
table name (`string`), and the columns that the table has

```d
auto users = new Table(
  "users", // table name
  "id",    // the rest are columns
  "name",
  "created_at",
  "updated_at");
```

A query selecting all rows in users can be generated like so:
```d
users.project(new Sql("*")).to_sql;
// SELECT * FROM users
```

Columns are accessed by calling the column's name on the table, or by
indexing the table with the column's name:

```d
users["id"];
users.id;
// The above are equivalent expressions
```

`.where` called on a regal node can be used to supply a where clause:
```d
users.where(users.id.eq(1)).project(new Sql("*")).to_sql
// SELECT * FROM users WHERE users.id = 1
```

`.where` can be chained to supply further constriants on the clause:
```d
users
  .where(users.id.eq(1))
  .where(users.name.like("%d%"))
  .to_sql

// SELECT * FROM users WHERE (users.id = 1) OR (users.name LIKE "%d%")
```

Nearly all methods can be composed to produce complex queries:
```d
// Submission made by a user
submissions = new regal.Table(
  "submissions",
  "id", "url", "user_id");

// Tags on a submission
tags = new regal.Table(
  "tags",
  "id", "value", "submission_id");

tags
  .join(submissions, submissions.id.eq(tags.submission_id))
  .join(users,       users.id.eq(submissions.user_id))
  .where(users.id.eq(1))
  .project(new Sql("*"))
  .to_sql

// SELECT * FROM tags
//  INNER JOIN submissions ON (submissions.id = tags.submission_id)
//  INNER JOIN users ON (users.id = submissions.user_id)
// WHERE (users.id = 1)
```

#### Group, Limit, Skip, Order
Rows can be grouped, limited, skipped , and ordered. `group` and `order` can take
a variable number of nodes as arguments. `asc`, `desc`, and `order(string)` can be
called on columns to specify a predefined column ordering, or a custom order if needed.

```d
// Get the 9th user in the table
users
  .order(users.id.asc)
  .skip(9)
  .limit(1)
  .project(new Sql("*"))
  .to_sql
// SELECT * FROM users ORDER BY users.id SKIP 9 LIMIT 1
```

```d
// Group by tag value
tags
  .group(tags.value)
  .project(tags.value)
  .to_sql
// SELECT tags.value FROM tags GROUP BY tags.value
```

#### Join types
The `Join.Type` enum defines common joins for tables, defaulting to an `Inner` join.
Calling `.join` with a different type of join (or a string) will use that join.

Members on `Join.Type`:
 - `Inner`
 - `LeftOuter`
 - `FullOuter`

```d
tags
  .join(submissions, Join.Type.LeftOuter, submissions.id.eq(tags.submission_id))
  .join(users,       "CUSTOM JOIN", users.id.eq(submissions.user_id))
  .where(users.id.eq(1))
  .project(new Sql("*"))
  .to_sql

// SELECT * FROM tags
//  LEFT OUTER JOIN submissions ON (submissions.id = tags.submission_id)
//  CUSTOM JOIN users ON (users.id = submissions.user_id)
// WHERE (users.id = 1)
```

#### Column operators
Columns support the entire range of SQL binary operators.

| Expression | SQL |
| -----------| ----|
| `users.id.eq(1)` | `users.id = 1` |
| `users.id.ne(1)` | `users.id <> 1` |
| `users.id.lt(1)` | `users.id < 1` |
| `users.id.lte(1)` | `users.id <= 1` |
| `users.id.gt(1)` | `users.id > 1` |
| `users.id.gte(1)` | `users.id >= 1` |
| `users.name.like("foo")` | `users.name LIKE "foo"` |
| `users.name.not_like("foo")` | `users.name NOT LIKE "foo"` |
| `users.id.in([1, 2])` | `users.id IN (1, 2)` |
| `users.id.not_in([3, 4])` | `users.id NOT IN (3, 4)` |


