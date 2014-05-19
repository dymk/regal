module regal.unittests;

private import regal;

// Test tables for unittests
// Note that tests aren't going to semantically make sense
// all the time -- for instance, in testing wheres, a join is not
// performed, but a cross table comparison is made. This obviously
// is not valid, but it's only for testing that the right SQL is generated.
private static Table users, tags, submissions;
static this() {
  // registered users
  users = regal.Table(
    "users",
    "id",
    "name",
    "register_time");

  // Submission made by a user
  submissions = regal.Table(
    "submissions",
    "id",
    "url",
    "user_id");

  // Tags on a post
  tags = regal.Table(
    "tags",
    "id",
    "value",
    "submission_id");
}

private void renders_same(N)(N n, string should_be) {
  import std.string : strip;
  // ignore trailing/leading whitespace
  auto res = n.to_sql().strip;
  assert(res == should_be,
    "\nwas:              `" ~ res ~ "`" ~
    "\nshould have been: `" ~ should_be ~ "`");
}

// Test inner joins
unittest {
  renders_same(
    tags.join(submissions, submissions.id.eq(tags.submission_id)),
    "INNER JOIN submissions ON (submissions.id = tags.submission_id)");
}
// Test join composition
unittest {
  renders_same(
    tags
      .join(submissions, submissions.id.eq(tags.submission_id))
      .join(users,       users.id.eq(submissions.user_id))
      .where(users.id.eq(1)),
      "INNER JOIN submissions ON (submissions.id = tags.submission_id) "
      "INNER JOIN users ON (users.id = submissions.user_id) "
      "WHERE (users.id = 1)");
}

// Test projection
unittest {
  renders_same(
    tags.project(Sql("*")),
    "SELECT * FROM tags");
}
unittest {
  renders_same(
    tags.project(tags.id, tags.value),
    "SELECT tags.id, tags.value FROM tags");
}
unittest {
  renders_same(
    tags.project(Sql("submission_id")),
    "SELECT submission_id FROM tags");
}

// Where
unittest {
  renders_same(
    tags.where(tags.id.eq(1)),
    "WHERE (tags.id = 1)");
}
unittest {
  renders_same(
    tags.where(tags.id.eq(users.id)),
    "WHERE (tags.id = users.id)");
}

// Chaining constraints
unittest {
  renders_same(
    tags
      .where(tags.value.like("%foo%"))
      .or(tags.value.like("%bar%"))
      .and(tags.id.lt(5).or(tags.id.gt(0))),
    `WHERE (((tags.value LIKE "%foo%") OR (tags.value LIKE "%bar%")) AND `
    `((tags.id < 5) OR (tags.id > 0)))`);
}

// Chaining .where
unittest {
  renders_same(
    tags
      .where(tags.id.eq(1))
      .where(tags.value.eq("foobar")),
    `WHERE ((tags.id = 1) AND (tags.value = "foobar"))`);
}

// Limit and skip
unittest {
  renders_same(
    tags.limit(1).skip(2),
    "LIMIT 1 SKIP 2");
}

// Operators on columns
unittest {
  renders_same(
    tags.id.eq(1),
    "(tags.id = 1)");
}
unittest {
  renders_same(
    tags.value.like("%foo%"),
    "(tags.value LIKE \"%foo%\")");
}
unittest {
  renders_same(
    tags.id._in([4, 5, 6]),
    "(tags.id IN (4, 5, 6))");
}
unittest {
  renders_same(
    tags.id.eq(1).or(tags.id.eq(2)),
    "((tags.id = 1) OR (tags.id = 2))");
}
unittest {
  renders_same(
    tags.id.eq(1).and(tags.value.eq("foo")),
    "((tags.id = 1) AND (tags.value = \"foo\"))");
}

// column ordering
unittest {
  renders_same(
    tags.order(tags.id),
    "ORDER BY tags.id");
}
unittest {
  renders_same(
    tags.order(tags.id.desc),
    "ORDER BY tags.id DESC");
}
unittest {
  renders_same(
    tags.order(tags.id.asc),
    "ORDER BY tags.id ASC");
}
unittest {
  // custom ordering string
  renders_same(
    tags.order(tags.id.order("foo")),
    "ORDER BY tags.id foo");
}
unittest {
  // multiple column ordering
  renders_same(
    tags.order(tags.id, tags.value),
    "ORDER BY tags.id, tags.value");
}

// grouping
unittest {
  renders_same(
    tags.group(tags.id),
    "GROUP BY tags.id");
}
unittest {
  renders_same(
    tags.group(tags.id, tags.value),
    "GROUP BY tags.id, tags.value");
}

// Test arbitrary type to_sql
unittest {
  static struct Data {
    int id;

    int to_sql() {
      return id;
    }
  }

  auto datas = new regal.Table("datas", "id");
  auto arr = [Data(1), Data(2), Data(3)];

  renders_same(
    datas.id._in(arr),
    "(datas.id IN (1, 2, 3))");
}
