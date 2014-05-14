module regal.ast;

private {
  import regal;
  import std.array;
}

// Root node for all SQL syntax trees
abstract class Node {
  const string table;

  this(string table) {
    this.table = table;
  }

  void accept(Visitor v);

  string toSql() {
    scope a = appender!string();
    scope visitor = new MySqlPrinter!(Appender!string);
    visitor.run(this, a);
    return a.data();
  }

  final BinOp limit(int amt) {
    return new BinOp(
      table, BinOp.Kind.Limit,
      this, new LitNodeImpl!int(table, amt));
  }

  final BinOp skip(int amt) {
    return new BinOp(
      table, BinOp.Kind.Skip,
      this, new LitNodeImpl!int(table, amt));
  }

  final BinOp order(Node by) {
    return new BinOp(
      table, BinOp.Kind.Order,
      this, by);
  }
  final BinOp order(Node[] by...) {
    return order(nodelist_from_arr(by));
  }

  final BinOp group(Node by) {
    return new BinOp(
      table, BinOp.Kind.Group,
      this, by);
  }
  final BinOp group(Node[] by...) {
    return group(nodelist_from_arr(by));
  }
}

// SELECT <projection> FROM <table> [<clause>]
class Project : Node {
  Node projection;
  Node clause;

  this(string table, Node projection, Node clause) {
    super(table);
    this.projection = projection;
    this.clause = clause;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }
}

// List of nodes, a-la a list of columns to project
// e.g.
class NodeList : Node {
  // possibly null
  NodeList next;
  Node child;

  this(Node child, NodeList next) {
    super(null);
    this.child = child;
    this.next = next;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }
}

// Node representing raw SQL
class Sql : Node {
  this(string sql) {
    super(null);
    this.sql = sql;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }

  string sql;
}

// Operator chainable node
abstract class ClauseNode : Node {

protected:
  this(string table) {
    super(table);
  }

public:
  // chained 'where' is implemented as an 'and'
  ClauseNode where(ClauseNode child) {
    return and(child);
  }

  // <clause>.and(<clause>)
  ClauseNode and(ClauseNode rhs) {
    return new BinOp(
      table, BinOp.Kind.And,
      this, rhs);
  }

  // <clause>.or(<clause>)
  ClauseNode or(ClauseNode rhs) {
    return new BinOp(
      table, BinOp.Kind.Or,
      this, rhs);
  }

  // <clause>.project(<nodes>)
  Project project(Node[] projections...) {
    return project(nodelist_from_arr(projections));
  }
  Project project(Node projection) {
    return new Project(
      table, projection, this);
  }

  As as(string as_name) {
    return new As(
      table, as_name, this);
  }
}

// Join clause
class Join : Node, ITable {
  string other_table_name;
  ClauseNode on;    // optional
  Node lhs_node;    // Optional

  this(string table, string other_table_name, ClauseNode on, Node lhs_node) {
    super(table);
    this.other_table_name = other_table_name;
    this.on = on;
    this.lhs_node = lhs_node;
  }

  override string table() @property {
    return super.table;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }

  override Node this_as_lhs() {
    return this;
  }
}

// Where clause operator
class Where : ClauseNode {
  Node child;
  Node lhs; // optional

  this(string table, Node child, Node lhs = null) {
    super(table);
    this.child = child;
    this.lhs = lhs;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }
}

// As clause operator
class As : ClauseNode {
  Node child;
  string as_name;

  this(string table, string as_name, Node child) {
    super(table);
    this.as_name = as_name;
    this.child = child;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }
}

// A literal node (needed as Visitor can't take a
// templated LitNodeImpl)
abstract class LitNode : ClauseNode {
  this(string table) { super(table); }

  override void accept(Visitor v) {
    v.visit(this);
  }
}

// Actual implementation of LitNode (holds any type T)
class LitNodeImpl(T) : LitNode {
  T lit;

  this(string table, ref T lit) {
    super(table);
    this.lit = lit;
  }

  override string toString() const {
    import std.conv : to;
    static if(is(T : const(char)[])) {
      return `"` ~ lit.to!string ~ `"`;
    }
    else {
      return lit.to!string;
    }
  }
}

// A binary operator relating two other nodes
class BinOp : ClauseNode {
  enum Kind {
    And,
    Or,
    Eq,
    Ne,
    Lt,
    Lte,
    Gt,
    Gte,
    Limit,
    Skip,
    Group,
    Order
  }

  Kind kind;
  Node rhs;
  Node lhs;

  this(string table, Kind k, Node l, Node r) {
    super(table);
    this.kind = k;
    this.lhs = l;
    this.rhs = r;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }
}

final class NullNode : Node {
  this() { super(null); }

  override void accept(Visitor v) {
    v.visit(this);
  }
}
