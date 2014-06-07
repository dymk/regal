module regal.unittests;

private {
  import regal;
  import std.stdio;
  import std.range;
}

private static const Table users, tags, submissions;
static this() {
  // registered users
  users = new Table(
    "users",
    ["id",
    "name",
    "register_time"]);

  // Submission made by a user
  submissions = new Table(
    "submissions",
    ["id",
    "url",
    "user_id"]);

  // Tags on a post
  tags = new Table(
    "tags",
    ["id",
    "value",
    "submission_id"]);
}

private bool renders_same(const Node n, in string should_be) {
  import std.string : strip;

  auto printer = new SqlitePrinter!(Appender!string)();
  auto accum = appender!string();

  printer.run(n, accum);

  // ignore trailing/leading whitespace
  assert(accum.data == should_be,
    "\nwas:              `" ~ accum.data ~ "`" ~
    "\nshould have been: `" ~ should_be  ~ "`");

  return true;
}

// ensure basic CTFE works
unittest {
  const t = new Table("users", ["id", "name", "age"]);
  static assert(renders_same(
    t.select(Sql("*")),
    "SELECT * FROM users"));
}

unittest { // right table name is printed
  renders_same(
    users,
    "users");
}

unittest { // explicit where clause

  renders_same(
    users.where(new Sql("1 = 1")),
    "SELECT * FROM users WHERE 1 = 1");
}
unittest { // explicit where clause
  renders_same(
    users.where(null),
    "SELECT * FROM users WHERE NULL");
}

unittest { // select only one column
  renders_same(
    users.select(users.id),
    "SELECT users.id FROM users");
}

unittest { // select specific columns
  renders_same(
    users.select(users.id, users.name),
    "SELECT users.id, users.name FROM users");
}

unittest { // binop w/ another column
  renders_same(
    users.where(users.id.eq(users.name)),
    "SELECT * FROM users WHERE (users.id = users.name)");
}

unittest {
  renders_same( // BinOp w/ a constant
    users.where(users.id.eq(2)),
    "SELECT * FROM users WHERE (users.id = 2)");
}
unittest { // BinOp w/ array
  renders_same(
    users.where(users.id._in([1, 2, 3])),
    "SELECT * FROM users WHERE (users.id IN (1, 2, 3))");
}
unittest { // BinOp w/ ranges
  renders_same(
    users.where(users.id.not_in(std.range.iota(5, 8, 1))),
    "SELECT * FROM users WHERE (users.id NOT IN (5, 6, 7))");
}

/************** #join *************/
unittest { // simple join with an 'on'
  renders_same(
    tags.join(submissions, submissions.id.eq(tags.submission_id)).select(Sql("*")),
    "SELECT * FROM tags INNER JOIN submissions ON (submissions.id = tags.submission_id)");
}
unittest { // simple join with a custom 'on'
  renders_same(
    tags.join(submissions, Sql("submission_id = submissions.id")).select(Sql("*")),
    "SELECT * FROM tags INNER JOIN submissions ON submission_id = submissions.id");
}
unittest {
  renders_same( // chained, more complex join
    tags
      .join(submissions, submissions.id.eq(tags.submission_id))
      .join(users,       users.id.eq(submissions.user_id))
      .where(users.id.eq(1)),
      "SELECT * FROM tags "
      "INNER JOIN submissions ON (submissions.id = tags.submission_id) "
      "INNER JOIN users ON (users.id = submissions.user_id) "
      "WHERE (users.id = 1)");
}

/*********** #where ***************/
// Chaining .where
unittest {
  renders_same(
    tags
      .where(tags.id.eq(1))
      .where(tags.value.eq("foobar")),
    `SELECT * FROM tags WHERE ((tags.id = 1) AND (tags.value = "foobar"))`);
}

/********** Limitable interface **********/
unittest {
  renders_same(
    tags.limit(1),
    "SELECT * FROM tags LIMIT 1");
}
unittest {
  renders_same(
    tags.skip(1),
    "SELECT * FROM tags SKIP 1");
}
unittest {
  renders_same(
    tags.limit(1).skip(2),
    "SELECT * FROM tags LIMIT 1 SKIP 2");
}

/******* operators on columns *************/
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
unittest {
  renders_same(
    tags.order(tags.id),
    "SELECT * FROM tags ORDER BY tags.id");
}
unittest {
  renders_same(
    tags.order(tags.id.desc),
    "SELECT * FROM tags ORDER BY tags.id DESC");
}
unittest {
  renders_same(
    tags.order(tags.id.asc),
    "SELECT * FROM tags ORDER BY tags.id ASC");
}
unittest {
  // custom ordering string
  renders_same(
    tags.order(tags.id.order("foo")),
    "SELECT * FROM tags ORDER BY tags.id foo");
}
unittest {
  // multiple column ordering
  renders_same(
    tags.order(tags.id, tags.value),
    "SELECT * FROM tags ORDER BY tags.id, tags.value");
}
unittest {
  renders_same( // group by a column
    tags.group(tags.id),
    "SELECT * FROM tags GROUP BY tags.id");
}
unittest {
  renders_same( // group by multiple columns
    tags.group(tags.id, tags.value),
    "SELECT * FROM tags GROUP BY tags.id, tags.value");
}
unittest {
  renders_same( // group by custom string
    tags.group(Sql("foo")),
    "SELECT * FROM tags GROUP BY foo");
}
unittest {
  renders_same( // column 'as'
    tags.select(tags.value.as("tag_value")),
    "SELECT tags.value AS tag_value FROM tags");
}

version(none)
unittest {
  // Triggers an LDC bug (see bug in ast/select.d `class Select` ctor)
  auto w = users.where(new Sql("1 = 1"));

  auto var = (cast(Select)w.left).projection[0];
  auto var2 = cast(Node) var;
  auto printer = new SqlitePrinter!(Appender!string)();
  auto accum = appender!string();

  printer.run(w, accum);
  import std.conv;
  std.stdio.writeln(var);
}
