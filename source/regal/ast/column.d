module regal.ast.column;

private {
  import regal.ast;
  import regal.visitor;
  import std.string;
}

abstract class Column : Node {
  const string table_name;
  const string name;

  this(const string table_name, const string name) @safe pure nothrow {
    this.table_name = table_name;
    this.name = name;
  }
}

/// Has no ordering, but one can be applied to it
final class UnorderedColumn : Column, WhereCondition {
  mixin(generate_op_str("lt", "Lt"));
  mixin(generate_op_str("lte", "Lte"));
  mixin(generate_op_str("gt", "Gt"));
  mixin(generate_op_str("gte", "Gte"));
  mixin(generate_op_str("eq", "Eq"));
  mixin(generate_op_str("ne", "Ne"));
  mixin(generate_op_str("_in", "In"));
  mixin(generate_op_str("not_in", "NotIn"));
  mixin(generate_op_str("like", "Like"));
  mixin(generate_op_str("not_like", "NotLike"));
  //#line 32 "regal/ast/column.d"

  this(const string table_name, const string name) @safe pure nothrow {
    super(table_name, name);
  }

  AsColumn as(string as_name) @safe pure nothrow const
  {
    return new AsColumn(this, as_name);
  }

  OrderedColumn asc()
  @safe pure nothrow const
  {
    return new OrderedColumn(this, OrderedColumn.Dir.Asc);
  }
  OrderedColumn desc()
  @safe pure nothrow const
  {
    return new OrderedColumn(this, OrderedColumn.Dir.Desc);
  }
  OrderedColumn order(string dir)
  @safe pure nothrow const
  {
    return new OrderedColumn(this, OrderedColumn.Dir.Other, dir);
  }

private:
  // binary operation a primitive
  WhereCondition bin_with(T)(BinaryCompare.Op kind, const T other)
  @trusted pure nothrow const
  if(!isClass!T)
  {
    return new BinaryCompare(kind,
      cast(const(WhereCondition)) this,
      cast(const(WhereCondition)) new LitNode!T(other));
  }

  // binary operation with another column node
  WhereCondition bin_with(
    const BinaryCompare.Op kind,
    const UnorderedColumn other)
  @trusted pure nothrow const
  {
    return new BinaryCompare(kind,
      cast(const(WhereCondition)) this,
      cast(const(WhereCondition)) other);
  }

public:
  mixin AcceptVisitor2;
}

/// Aliased column
final class AsColumn : Column {
  const string original_name;

  this(const UnorderedColumn other, string new_name) @safe pure nothrow
  {
    super(other.table_name, new_name);
    this.original_name = other.name;
  }

  mixin AcceptVisitor2;
}

// Column with an ordering; used in Order(OrderedColumn[] ...) nodes
final class OrderedColumn : Column {
  enum Dir {
    Asc,
    Desc,
    Other
  }

  const Dir dir;
  const string order_str;

  this(const Column parent, Dir dir, const string order_str = "")
  @safe pure nothrow
  {
    super(parent.table_name, parent.name);

    this.dir = dir;
    if(dir == Dir.Other) {
      this.order_str = order_str;
    }
    else {
      this.order_str = "";
    }
  }

  mixin AcceptVisitor2;
}

// Generate operator methods, given the op's name, and the BinaryCompare Op
// on BinaryCompare.Op
private
string generate_op_str(string op_name, string binop_kind) {
  return "
    auto %s(V)(V other) @safe pure nothrow const
    {
      return bin_with(BinaryCompare.Op.%s, other);
    }
  ".format(op_name, binop_kind);
}
