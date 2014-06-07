module regal.ast.column;

private {
  import regal.ast;
  import regal.visitor;
  import std.string;
}

/// Interface common to all node types
interface Column : Node {}

/// Has no ordering, but one can be applied to it
final class UnorderedColumn : Column, WhereCondition {
  const string table_name;
  const string name;

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
    this.table_name = table_name;
    this.name = name;
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

  mixin AndOrableImpl;

private:
  // binary operation a primitive
  BinaryCompare bin_with(T)(BinaryCompare.Op kind, T other)
  @trusted pure nothrow const
  if(!isClass!T)
  {
    return new BinaryCompare(kind,
      cast(const(WhereCondition)) this,
      cast(WhereCondition) new LitNode!T(other));
  }

  // binary operation with another column node
  BinaryCompare bin_with(
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
final class AsColumn : Column, WhereCondition {
  const UnorderedColumn root;
  const string as_name;

  this(const UnorderedColumn root, string new_name) @safe pure nothrow
  {
    this.root = root;
    this.as_name = new_name;
  }

  mixin AcceptVisitor2;
}

// Column with an ordering; used in Order(OrderedColumn[] ...) nodes
final class OrderedColumn : Column, WhereCondition {
  enum Dir {
    Asc,
    Desc,
    Other
  }

  const UnorderedColumn root;
  const Dir dir;
  const string order_str;

  this(const UnorderedColumn root, Dir dir, const string order_str = "")
  @safe pure nothrow
  {
    this.root = root;

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
    BinaryCompare %s(V)(V other) @safe pure nothrow const
    {
      return bin_with(BinaryCompare.Op.%s, other);
    }
  ".format(op_name, binop_kind);
}
