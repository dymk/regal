module regal.ast;

private {
  import regal;
  import std.array;
}

struct NodeStore {
  mixin node_methods;

  enum Type {
    Invalid,
    NodeClass,
    WhereStruct,
    SqlStruct
  }

private:
  Type type = Type.Invalid;
  union {
    Node node;
    Where* where;
    Sql sql;
  }

public:
  this(Node node) {
    this.node = node;
    this.type = Type.NodeClass;
  }

  this(Sql sql) {
    this.sql = sql;
    this.type = Type.SqlStruct;
  }

  this(Where* where) {
    this.where = where;
    this.type = Type.WhereStruct;
  }

  this(NodeStore ns) {
    this.type = ns.type;
    final switch(ns.type)
    with(Type) {
      case Invalid: break;
      case NodeClass: this.node = ns.node; break;
      case SqlStruct: this.sql = ns.sql; break;
      case WhereStruct: this.where = ns.where; break;
    }
  }

  bool opCast(T : bool)() {
    if(type == Type.NodeClass) {
      return this.node !is null;
    }
    else {
      return (type != Type.Invalid);
    }
  }

  void accept(Visitor v) {
    final switch(type)
    with(Type)
    {
      case Invalid: assert(false, "Can't visit Invlaid NodeStore");
      case NodeClass: if(this.node) this.node.accept(v); break;
      case SqlStruct: this.sql.accept(v);  break;
      case WhereStruct: this.where.accept(v);  break;
    }
  }
}

// Node representing raw SQL
struct Sql {
  mixin node_methods;

  this(string sql) {
    this.sql = sql;
  }

  void accept(Visitor v) {
    v.visit(this);
  }

  string sql;
}


// Where clause operator
struct Where {
  mixin node_methods;

  NodeStore child;
  Node lhs; // optional
  string table;

  this(N)(string table, N child, Node lhs = null) {
    this.table = table;
    this.child = NodeStore(child);
    this.lhs = lhs;
  }

  // Override to not wrap WHERE in parens (just generate another
  // WHERE with a BinOp'd child)
  Where* and(N)(N rhs) {
    return new Where(
      table,
      new BinOp(
        table, BinOp.Kind.And,
        child, rhs),
      lhs);
  }
  Where* or(N)(N rhs) {
    return new Where(
      table,
      new BinOp(
        table, BinOp.Kind.Or,
        child, rhs),
      lhs);
  }

  // Chained where implemented as 'and'
  Where* where(N)(N rhs) {
    return and(rhs);
  }

  void accept(Visitor v) {
    v.visit(this);
  }
}

// Root node for all SQL syntax trees
abstract class Node {
  mixin node_methods;

  const string table;

  this(string table) {
    this.table = table;
  }

  void accept(Visitor v);
}

// SELECT <projection> FROM <table> [<clause>]
class Project : Node {
  Node projection;
  NodeStore clause;

  this(N)(string table, Node projection, N clause) {
    super(table);
    this.projection = projection;
    this.clause = NodeStore(clause);
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
  NodeStore child;

  this(N)(N child, NodeList next) {
    super(null);
    this.child = NodeStore(child);
    this.next = next;
  }

  override void accept(Visitor v) {
    v.visit(this);
  }
}

// Operator chainable node
abstract class ClauseNode : Node {

protected:
  this(string table) {
    super(table);
  }

public:
  // chained 'where' is implemented as an 'and'
  ClauseNode where(N)(N child) {
    return and(child);
  }

  // <clause>.and(<clause>)
  ClauseNode and(N)(N rhs) {
    return new BinOp(
      table, BinOp.Kind.And,
      this, rhs);
  }

  // <clause>.or(<clause>)
  ClauseNode or(N)(N rhs) {
    return new BinOp(
      table, BinOp.Kind.Or,
      this, rhs);
  }

  // <clause> AS as_name
  ClauseNode as(string as_name) {
    return new BinOp(
      table, BinOp.Kind.As,
      this, Sql(as_name));
  }

  // Methods for satisfying CommonMethods
  string table() @property {
    return super.table;
  }

  Node this_as_lhs() { return this; }

  mixin common_methods;
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
  NodeStore rhs;
  NodeStore lhs;

  this(N, V)(string table, Kind k, N l, V r) {
    super(table);
    this.kind = k;
    this.lhs = NodeStore(l);
    this.rhs = NodeStore(r);
  }

  override void accept(Visitor v) {
    v.visit(this);
  }
}
