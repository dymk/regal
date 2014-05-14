module regal.visitor;

private {
  import regal;
  import std.range;
  import std.conv;
}

interface Visitor {
  void visit(ColNode n);
  void visit(LitNode n);
  void visit(Sql s);
  void visit(BinOp n);
  void visit(Where n);
  void visit(Project p);
  void visit(NodeList n);
}

class MySqlPrinter(Out) : Visitor
if(isOutputRange!(Out, string))
{
  Out accum;
  void run(Node root, Out accum) {
    this.accum = accum;
    root.accept(this);
  }

  override void visit(ColNode n) {
    accum.put("`");
    accum.put(n.table);
    accum.put("`.`");
    accum.put(n.col);
    accum.put("`");
  }

  override void visit(LitNode n) {
    accum.put(n.toString());
  }

  override void visit(Sql s) {
    accum.put(s.sql);
  }

  override void visit(BinOp b) {
    string opstr;
    bool add_parens = true;
    final switch(b.kind)
    with(BinOp.Kind) {
      case Eq:  opstr = " = "; break;
      case Ne:  opstr = " <> "; break;
      case Lt:  opstr = " < "; break;
      case Gt:  opstr = " > "; break;
      case Lte: opstr = " <= "; break;
      case Gte: opstr = " >= "; break;

      case And: opstr = " AND "; add_parens = false; break;
      case Or:  opstr = " OR ";  add_parens = false; break;
    }

    if(add_parens) accum.put("(");
    b.lhs.accept(this);

    accum.put(opstr);

    b.rhs.accept(this);
    if(add_parens) accum.put(")");
  }

  override void visit(Where w) {
    accum.put("WHERE ");
    w.child.accept(this);
  }

  override void visit(Project s) {
    accum.put("SELECT ");
    s.projection.accept(this);
    accum.put(" FROM");

    accum.put(" `");
    accum.put(s.table);
    accum.put("` ");

    if(s.clause) {
      s.clause.accept(this);
    }
  }

  override void visit(NodeList n) {
    n.child.accept(this);

    if(n.next !is null) {
      accum.put(", ");
      n.next.accept(this);
    }
  }
}
