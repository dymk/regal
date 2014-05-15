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

  string to_sql() {
    scope a = appender!string();
    scope visitor = new MySqlPrinter!(Appender!string);
    visitor.run(this, a);
    return a.data();
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
abstract class ClauseNode : Node, CommonMethods {

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

  // <clause> AS as_name
  ClauseNode as(string as_name) {
    return new BinOp(
      table, BinOp.Kind.As,
      this, new Sql(as_name));
  }

  // Methods for satisfying CommonMethods
  string table() @property {
    return super.table;
  }
  Node this_as_lhs() { return this; }
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

  // Override to not wrap WHERE in parens (just generate another
  // WHERE with a BinOp'd child)
  override ClauseNode and(ClauseNode rhs) {
    return new Where(
      table,
      new BinOp(
        table, BinOp.Kind.And,
        child, rhs)
      , lhs);
  }
  override ClauseNode or(ClauseNode rhs) {
    return new Where(
      table,
      new BinOp(
        table, BinOp.Kind.Or,
        child, rhs)
      , lhs);
  }

  override void accept(Visitor v) {
    v.visit(this);
  }
}

// A literal node
class LitNode(T) : ClauseNode {
  T lit;

  this(string table, ref T lit) {
    super(table);
    this.lit = lit;
  }

  override void accept(Visitor v) {
    import std.range : isInputRange;
    import std.traits : isSomeString;
    static if(
      isInputRange!T &&
      !isSomeString!T) {
      // lit is a range

      v.start_array();

      bool first = true;
      foreach(lit_elem; lit) {
        if(first) {
          first = false;
        }
        else {
          v.array_sep();
        }

        visit_nonrange_lit(v, lit_elem);
      }

      v.end_array();
    }

    else {
      // lit is not a range, print it directly
      visit_nonrange_lit(v, lit);
    }
  }

private:
  static void visit_nonrange_lit(U)(Visitor v, ref U l) {
    // try using a predefined lit printing method
    static if(__traits(compiles, {
      v.visit_lit(l);
    })) {
      v.visit_lit(l);
    }

    // try calling to_sql on the instance
    else static if(__traits(compiles, {
      v.visit_lit(l.to_sql());
    })) {
      v.visit_lit(l.to_sql());
    }

    // fallback to directly converting it to a string
    else {
      import std.conv : to;
      v.visit_lit(l.to!string);
    }
  }
}

// A binary operator relating two other nodes
class BinOp : ClauseNode {
  enum Kind {
    And, Or,
    Eq, Ne,
    Lt, Lte,
    Gt, Gte,
    In, NotIn,
    Like, NotLike,
    As,
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
