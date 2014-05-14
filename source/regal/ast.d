module regal.ast;

private {
  import regal;
  import std.array;
}

// Root node for all SQL syntax trees
abstract class Node {
  void accept(Visitor v);

  string toSql() {
    scope a = appender!string();
    scope visitor = new MySqlPrinter!(Appender!string);
    visitor.run(this, a);
    return a.data();
  }
}

// SELECT <projection> FROM <table> [<clause>]
class Project : Node {
  Node projection;
  string table;
  Node clause;

  this(string table, Node projection, ClauseNode clause) {
    assert(table && table != "");

    this.projection = projection;
    this.table = table;
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
    this.sql = sql;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }

  string sql;
}

// Operator chainable node
abstract class ClauseNode : Node {
  const string table;

protected:
  this(string table) {
    assert(table && table != "");
    this.table = table;
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

  Project project(Node[] projections...) {
    return project(nodelist_from_arr(projections));
  }
  Project project(Node projection) {
    return new Project(
      table, projection, this);
  }
}

// Where clause operator
class Where : ClauseNode {
  Node child;

  this(string table, Node child) {
    super(table);
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
    return lit.to!string;
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
