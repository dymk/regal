module regal.unittests;

private {
  import regal;
  import std.stdio;
  import std.range;
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

static const Table users;
static this() {
  users = new Table("users", ["id", "name", "age"]);
}

// ensure basic CTFE works
unittest {
  const t = new Table("users", ["id", "name", "age"]);
  static assert(renders_same(
    t.select(Sql("*")),
    "SELECT * FROM users"));
}

unittest {
  renders_same(
    users,
    "users");
}

unittest {
  renders_same(
    users.where(Sql("1 = 1")),
    "SELECT * FROM users WHERE 1 = 1");
}

unittest {
  renders_same(
    users.select(users.id),
    "SELECT id FROM users");
}

unittest {
  renders_same(
    users.select(users.id, users.name),
    "SELECT id, name FROM users");
}
