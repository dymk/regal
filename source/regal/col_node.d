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
