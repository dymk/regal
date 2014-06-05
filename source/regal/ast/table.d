module regal.ast.table;

private import regal.ast;

class Table : Limitable, Whereable, Node {

public:
  // cached map of column that the table has (by table_name)
  const Column[string] columns;
  const string table_name;

protected:
  this(const string table_name, const Column[string] columns) @safe pure nothrow
   {
    this.table_name    = table_name;
    this.columns = columns;
  }

public:
  /// Initialize with a table table_name, and an array of columns
  this(const string table_name, const string[] col_names) {
    this.table_name = table_name;

    Column[string] temp_cols;
    foreach(col_name; col_names) {
      temp_cols[col_name] = new UnorderedColumn(table_name, col_name);
    }

    this.columns = temp_cols;
  }

  /// Produce a new table with a join
  JoinedTable join(T)(
    const Table other,
    const WhereCondition on,
    in T type,
    string join_str = "")
  @safe pure nothrow const
  {
    return new JoinedTable(this, type, join_str, other, on);
  }

  // Alias table to another table_name
  AsTable as(string as_name) @safe pure nothrow const
  {
    return new AsTable(this, as_name);
  }

  /// Construct a 'select' with Sql("*") and delegate to its 'where'
  override SelectWhere where(const WhereCondition cond) @safe pure nothrow const
  {
    return select(Sql("*")).where(cond);
  }

  /// CRUD operations for the table
  Select select(const Node[] projection...) @safe pure nothrow const
  {
    return new Select(this, projection);
  }

  // TODO: implement these
  // Insert insert()  @safe pure nothrow const;
  // Update update()  @safe pure nothrow const;
  // Delete delete_() @safe pure nothrow const;

  /// Column getters
  const(Column) opDispatch(string col_name)() @safe pure nothrow const
  {
    return columns[col_name];
  }

  mixin AcceptVisitor;
}

/// Table joined with another table
final class JoinedTable : Table {
  /// Represents the join type (or a custom join string)
  enum Type {
    Inner,
    LeftOuter,
    FullOuter,
    Other
  }

  const Type type;
  // custom join string iff type == Type.Other
  const string join_str;

  // Table table_name being joined, and the "ON" clause
  const Table other_table;
  const WhereCondition on;

package:
  this(
    Table parent,
    Type type,
    string join_str,
    Table other_table,
    WhereCondition on)
  @safe pure nothrow
  {
    super(parent.table_name, parent.columns);
    this.type = type;
    this.other_table = other_table;
    this.on = on;

    if(type == Type.Other) {
      this.join_str = join_str;
    }
    else {
      this.join_str = "";
    }
  }

public:
  mixin AcceptVisitor;
}

final class AsTable : Table {
public:
  const string original_name;

package:
  this(const Table original, string new_name) @safe pure nothrow {
    super(new_name, original.columns);
    this.original_name = original.table_name;
  }

public:
  mixin AcceptVisitor;
}
