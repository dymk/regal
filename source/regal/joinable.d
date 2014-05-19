module regal.joinable;

private import regal;

mixin template joinable() {
  mixin common_methods;

  final Where* where(N)(N child) {
    return new Where(table, child, this_as_lhs());
  }

  // with a Table class and a clause
  final Join join(N)(Table other_table, N on)
  {
    return join(other_table.table, on);
  }
  // with a literal string and a clause
  final Join join(N)(string other_table, N on) {
    // default to inner join
    return join(other_table, Join.Type.Inner, on);
  }
  // same as above two, but with an explicit join type provided
  final Join join(N)(string other_table, Join.Type type, N on) {
    return new Join(table, other_table, on, this_as_lhs(), type);
  }
  final Join join(N)(string other_table, string join_str, N on) {
    return new Join(table, other_table, on, this_as_lhs(), join_str);
  }
}

// Join clause
// Implements ITable so join can be chained on it
class Join : Node {
  enum Type {
    Inner,
    LeftOuter,
    FullOuter,
    Other
  }

  // null iff type != Type.Other
  string join_str;
  Type type;

  string other_table_name;
  ClauseNode on;         // optional
  NodeStore lhs_node;    // Optional

  // initialize with a custom join string
  this(N)(string table, string other_table_name, ClauseNode on, N lhs_node, string join_str) {
    this(table, other_table_name, on, lhs_node, Type.Other);
    this.join_str = join_str;
  }

  // initialize with a predefined join string
  this(N)(string table, string other_table_name, ClauseNode on, N lhs_node, Type type) {
    this(table, other_table_name, on, lhs_node);
    this.type = type;
  }

private:
  this(N)(string table, string other_table_name, ClauseNode on, N lhs_node) {
    super(table);
    this.other_table_name = other_table_name;
    this.on = on;
    this.lhs_node = NodeStore(lhs_node);
  }

public:
  override void accept(Visitor v) {
    v.visit(this);
  }

  // For implementing ITable
  string table() @property {
    return super.table;
  }
  Node this_as_lhs() {
    return this;
  }

  mixin joinable;
}
