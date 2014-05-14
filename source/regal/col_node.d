module regal.col_node;

private {
  import regal;
  import std.string;
}

// Represents a column in the table
class ColNode : ClauseNode {
  string col;

  this(string table, string col) {
    super(table);
    this.col = col;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }

  mixin(generate_op_str("lt", "Lt"));
  mixin(generate_op_str("lte", "Lte"));
  mixin(generate_op_str("gt", "Gt"));
  mixin(generate_op_str("gte", "Gte"));
  mixin(generate_op_str("eq", "Eq"));
  mixin(generate_op_str("ne", "Ne"));
  #line 28 "regal/col_node.d"

  ColWithOrder asc() {
    return order("ASC");
  }
  ColWithOrder desc() {
    return order("DESC");
  }
  ColWithOrder order(string order) {
    return new ColWithOrder(table, this, order);
  }

private:
  // binop with a primitive
  ClauseNode bin_with(T)(BinOp.Kind kind, T other)
  if(!isClass!T)
  {
    return new BinOp(
      table, kind,
      this, new LitNodeImpl!T(table, other));
  }

  // binop with another column node
  ClauseNode bin_with(BinOp.Kind kind, ColNode other) {
    return new BinOp(
      table, kind,
      this, other);
  }
}

// Associates a ClauseNode with an additional direction to order by
// Internal to Order
class ColWithOrder : ClauseNode {
  ColNode col;
  string dir;

  this(string table, ColNode col, string dir) {
    super(table);
    this.col = col;
    this.dir = dir;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }
}

private:

// Generate operator methods, given the op's name, and the binop kind
// on BinOp.Kind
string generate_op_str(string op_name, string binop_kind) {
  return "
    auto %s(V)(V other)
    {
      return bin_with(BinOp.Kind.%s, other);
    }
  ".format(op_name, binop_kind);
}
