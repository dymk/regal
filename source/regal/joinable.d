module regal.joinable;

private import regal;

interface Joinable : CommonMethods {
  final Where where(ClauseNode child) {
    return new Where(table, child, this_as_lhs());
  }

  // with a Table class and a clause
  final Join join(Table other_table, ClauseNode on)
  {
    return join(other_table.table, on);
  }
  // with a literal string and a clause
  final Join join(string other_table, ClauseNode on) {
    // default to inner join
    return join(other_table, Join.Type.Inner, on);
  }
  // same as above two, but with an explicit join type provided
  final Join join(string other_table, Join.Type type, ClauseNode on) {
    return new Join(table, other_table, on, this_as_lhs(), type);
  }
  final Join join(string other_table, string join_str, ClauseNode on) {
    return new Join(table, other_table, on, this_as_lhs(), join_str);
  }
}

// Join clause
// Implements ITable so join can be chained on it
class Join : Node, Joinable {
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
  ClauseNode on;    // optional
  Node lhs_node;    // Optional

  // initialize with a custom join string
  this(string table, string other_table_name, ClauseNode on, Node lhs_node, string join_str) {
    this(table, other_table_name, on, lhs_node, Type.Other);
    this.join_str = join_str;
  }

  // initialize with a predefined join string
  this(string table, string other_table_name, ClauseNode on, Node lhs_node, Type type) {
    this(table, other_table_name, on, lhs_node);
    this.type = type;
  }

private:
  this(string table, string other_table_name, ClauseNode on, Node lhs_node) {
    super(table);
    this.other_table_name = other_table_name;
    this.on = on;
    this.lhs_node = lhs_node;
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
}
