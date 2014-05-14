import std.stdio;
import regal;

void main() {
  auto users = new regal.Table!(
    "users",
    int, "id",
    string, "name",
    int, "age");

  writeln("users.id:   ", users.id);
  writeln("users.name: ", users.name);
  writeln("users.age:  ", users.age);

  writeln("users.where(users.id.eq(10)): ", users.where(users.id.eq(10)).toSql());
  writeln("users.where(users.id.ne(10)): ", users.where(users.id.ne(10)).toSql());
  writeln("users.age.eq(users.id):       ", (users.age.eq(users.id)).toSql());

  writeln("users.where(users.name.eq(`dymk`)).where(users.age.eq(19)): \n\t",
    users.where(users.name.eq(`dymk`)).where(users.age.eq(19)).toSql());

  writeln("users.where(users.id.lt(10))",
    users.where(users.id.lt(10)).toSql());

  writeln("users.where(user.id.lt(users.age): \n\t",
    users.where(users.id.lt(users.age)).toSql());

  writeln("users.where(user.id.lte(users.age): \n\t",
    users.where(users.id.lte(users.age)).toSql());

  writeln("users.where(user.id.lte(users.age): \n\t",
    users.where(users.id.lte(users.age)).toSql());

  writeln("\n\n", users
      .where(users.id.eq(users.age))
      .and(  users.name.eq("dymk"))
      .project(new Sql("*"))
      .toSql());

  writeln("\n\n", users
      .where(users.id.eq(users.age))
      .and(  users.name.eq("dymk"))
      .project(users.id, users.name)
      .toSql());
}
