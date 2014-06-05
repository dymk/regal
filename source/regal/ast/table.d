module regal.ast.table;

private import regal.ast;

// Interface common to all Tables
abstract class ATable : Limitable, Whereable, Node {
  /// Produce a new table with a join
  JoinedTable join(
    const Table other,
    const WhereCondition on,
    in JoinType type = JoinType.Inner,
    in string join_str = "")
  @safe pure nothrow const
  {
    return new JoinedTable(this, type, join_str, other, on);
  }

  /// Construct a 'select' with Sql("*") and delegate to its 'where'
  override
  SelectWhere where(inout WhereCondition cond) @safe pure nothrow inout
  {
    return select(Sql("*")).where(cond);
  }

  /// CRUD operations for the table
  Select select(const Node[] projection...) @safe pure nothrow const
  {
    return new Select(this, projection);
  }
}

/// Actual table that the user interacts with 99% of the time
final class Table : ATable {
public:
  // cached map of column that the table has (by table_name)
  const UnorderedColumn[string] columns;
  const string table_name;

protected:
  this(const string table_name, const UnorderedColumn[string] columns) @safe pure nothrow
   {
    this.table_name = table_name;
    this.columns = columns;
  }

public:
  /// Initialize with a table table_name, and an array of columns
  this(in string table_name, in string[] col_names) {
    this.table_name = table_name;

    UnorderedColumn[string] temp_cols;
    foreach(col_name; col_names) {
      temp_cols[col_name] = new UnorderedColumn(table_name, col_name);
    }

    this.columns = temp_cols;
  }

  /// Alias table to another table_name
  AsTable as(string as_name) @safe pure nothrow const
  {
    return new AsTable(this, as_name);
  }

  // TODO: implement these
  // Insert insert()  @safe pure nothrow const;
  // Update update()  @safe pure nothrow const;
  // Delete delete_() @safe pure nothrow const;

  /// Column getters
  const(UnorderedColumn) opDispatch(string col_name)() @safe pure nothrow const
  {
    return columns[col_name];
  }

  mixin AcceptVisitor2;
}

/// Represents the join type (or a custom join string)
enum JoinType {
  Inner,
  LeftOuter,
  FullOuter,
  Other
}

/// Table joined with another table
final class JoinedTable : ATable {

  const JoinType type;
  // custom join string iff type == Type.Other
  const string join_str;

  // Table table_name being joined, and the "ON" clause
  const ATable parent;
  const Table other;
  const WhereCondition on;

package:
  this(
    const ATable parent,
    in JoinType type,
    in string join_str,
    const Table other,
    const WhereCondition on)
  @safe pure nothrow
  {
    this.parent = parent;
    this.type = type;
    this.other = other;
    this.on = on;

    if(type == JoinType.Other) {
      this.join_str = join_str;
    }
    else {
      this.join_str = "";
    }
  }

public:
  mixin AcceptVisitor2;
}

final class AsTable : Node {
public:
  const Table original;
  const string name;

package:
  this(const Table original, in string new_name) @safe pure nothrow {
    this.original = original;
    this.name = new_name;
  }

public:
  mixin AcceptVisitor2;
}
