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
  users = new regal.Table(
    "users",
    "id",
    "name",
    "register_time");

  // Submission made by a user
  submissions = new regal.Table(
    "submissions",
    "id",
    "url",
    "user_id");

  // Tags on a post
  tags = new regal.Table(
    "tags",
    "id",
    "value",
    "submission_id");
}

private void renders_same(Node n, string should_be) {
  import std.string : strip;
  auto res = n.to_sql().strip;
  assert(res == should_be, "should have been: `" ~ res ~ "`");
}

// Test inner joins
unittest {
  renders_same(
    tags.join(submissions, submissions.id.eq(tags.submission_id)),
    "INNER JOIN `submissions` ON (`submissions`.`id` = `tags`.`submission_id`)");
}

// Test projection
unittest {
  renders_same(
    tags.project(new Sql("*")),
    "SELECT * FROM `tags`");
}
unittest {
  renders_same(
    tags.project(tags.id, tags.value),
    "SELECT `tags`.`id`, `tags`.`value` FROM `tags`");
}
unittest {
  renders_same(
    tags.project(new Sql("submission_id")),
    "SELECT submission_id FROM `tags`");
}

// Where
unittest {
  renders_same(
    tags.where(tags.id.eq(1)),
    "WHERE (`tags`.`id` = 1)");
}
unittest {
  renders_same(
    tags.where(tags.id.eq(users.id)),
    "WHERE (`tags`.`id` = `users`.`id`)");
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
    "(`tags`.`id` = 1)");
}
unittest {
  renders_same(
    tags.value.like("%foo%"),
    "(`tags`.`value` LIKE \"%foo%\")");
}
unittest {
  renders_same(
    tags.id._in([4, 5, 6]),
    "(`tags`.`id` IN (4, 5, 6))");
}
unittest {
  renders_same(
    tags.id.eq(1).or(tags.id.eq(2)),
    "((`tags`.`id` = 1) OR (`tags`.`id` = 2))");
}
unittest {
  renders_same(
    tags.id.eq(1).and(tags.value.eq("foo")),
    "((`tags`.`id` = 1) AND (`tags`.`value` = \"foo\"))");
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
    "(`datas`.`id` IN (1, 2, 3))");
}
