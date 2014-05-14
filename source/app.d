import std.stdio;
import regal;

void main() {
  // Users
  auto users = new regal.Table!(
    "users",
    int, "id",
    string, "name",
    int, "register_time");

  // Submission made by a user
  auto submissions = new regal.Table!(
    "submissions",
    int, "id",
    string, "url",
    int, "user_id");

  // Tags on a post
  auto tags = new regal.Table!(
    "tags",
    int, "id",
    string, "value",
    int, "submission_id");

  // Get the tags on all the submissions that a user has made
  writeln(
    tags
    .join(submissions, submissions.id.eq(tags.submission_id))
    .join(users,       users.id.eq(submissions.user_id))
    .where(users.id.eq(1))
    .project(new Sql("*"))
    .toSql() );

  writeln(
    tags
    .join(submissions, submissions.id.eq(tags.submission_id))
    .join(users,       users.id.eq(submissions.user_id))
    .where(users.id.eq(1))
    .limit(10)
    .skip(13)
    .project(new Sql("*"))
    .toSql() );

  writeln(
    tags
    .limit(10)
    .skip(13)
    .project(new Sql("*"))
    .toSql() );

  writeln(
    tags
    .where(tags.value.eq("asdf"))
    .limit(10)
    .skip(13)
    .project(new Sql("*"))
    .toSql() );

  writeln(
    tags
    .group(tags.submission_id)
    .project(new Sql("*"))
    .toSql() );




  //writeln("users.id:   ", users.id);
  //writeln("users.name: ", users.name);
  //writeln("users.age:  ", users.age);

  //writeln("users.where(users.id.eq(10)): ", users.where(users.id.eq(10)).toSql());
  //writeln("users.where(users.id.ne(10)): ", users.where(users.id.ne(10)).toSql());
  //writeln("users.age.eq(users.id):       ", (users.age.eq(users.id)).toSql());

  //writeln("users.where(users.name.eq(`dymk`)).where(users.age.eq(19)): \n\t",
  //  users.where(users.name.eq(`dymk`)).where(users.age.eq(19)).toSql());

  //writeln("users.where(users.id.lt(10))",
  //  users.where(users.id.lt(10)).toSql());

  //writeln("users.where(user.id.lt(users.age): \n\t",
  //  users.where(users.id.lt(users.age)).toSql());

  //writeln("users.where(user.id.lte(users.age): \n\t",
  //  users.where(users.id.lte(users.age)).toSql());

  //writeln("users.where(user.id.lte(users.age): \n\t",
  //  users.where(users.id.lte(users.age)).toSql());

  //writeln("\n\n", users
  //    .where(users.id.eq(users.age))
  //    .and(  users.name.eq("dymk"))
  //    .project(new Sql("*"))
  //    .toSql());

  //writeln("\n\n", users
  //    .where(users.id.eq(users.age))
  //    .and(  users.name.eq("dymk"))
  //    .project(users.id, users.name)
  //    .toSql());

  //writeln("\n\n", users
  //    .where(users.id.eq(users.age))
  //    .and(  users.name.eq("dymk"))
  //    .project(users.id, users.name.as("user_name"))
  //    .group(users.id)
  //    .toSql());
}
