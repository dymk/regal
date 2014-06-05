module regal.sqlite_printer;

private {
  import regal;
  import std.range;
  import std.conv;
}

final class SqlitePrinter(Out) : Visitor
if(isOutputRange!(Out, string))
{
  Out accum;
  void run(N)(N root, Out accum) {
    this.accum = accum;
    root.accept(this);
  }

  override void visit(const Sql s) {
    accum.put(s.sql);
  }

  override void visit(const BinaryCompare b) {
    string opstr;
    bool add_parens = true;

    final switch(b.op)
    with(BinaryCompare.Op) {
      case Eq:  opstr = " = "; break;
      case Ne:  opstr = " <> "; break;
      case Lt:  opstr = " < "; break;
      case Gt:  opstr = " > "; break;
      case Lte: opstr = " <= "; break;
      case Gte: opstr = " >= "; break;

      case In:      opstr = " IN ";       break;
      case NotIn:   opstr = " NOT IN ";   break;
      case Like:    opstr = " LIKE ";     break;
      case NotLike: opstr = " NOT LIKE "; break;

      case And: opstr = " AND "; break;
      case Or:  opstr = " OR ";  break;
    }

    if(add_parens) accum.put("(");
    b.left.accept(this);

    accum.put(opstr);

    b.right.accept(this);
    if(add_parens) accum.put(")");
  }

  void visit(const Select s) {
    accum.put("SELECT");

    foreach(i, col; s.projection) {
      if(i != 0) {
        accum.put(", ");
      }
      else {
        accum.put(" ");
      }

      col.accept(this);
    }

    accum.put(" FROM ");
    s.table.accept(this);
  }

  void visit(const Where w) {
    w.left.accept(this);
    accum.put(" WHERE ");
    w.cond.accept(this);
  }

  void visit(const Limit l) {
    l.root.accept(this);
    accum.put(" LIMIT ");
    accum.put(l.amt.to!string);
  }

  void visit(const Skip) { assert(false); }
  void visit(const Group) { assert(false); }
  void visit(const Order) { assert(false); }

  void visit(const Table t) {
    accum.put(t.table_name);
  }

  void visit(const JoinedTable) { assert(false); }
  void visit(const AsTable) { assert(false); }

  void visit(const UnorderedColumn o) {
    accum.put(o.name);
  }
  void visit(const OrderedColumn) { assert(false); }
  void visit(const AsColumn) { assert(false); }

  //override void visit(Where w) {
  //  if(w.lhs) {
  //    w.lhs.accept(this);
  //    accum.put(" ");
  //  }

  //  accum.put("WHERE ");
  //  w.child.accept(this);
  //}

  //override void visit(Project s) {
  //  accum.put("SELECT ");
  //  s.projection.accept(this);
  //  accum.put(" FROM ");

  //  accum.put(s.table);

  //  if(s.clause) {
  //    accum.put(" ");
  //    s.clause.accept(this);
  //  }
  //}

  //override void visit(NodeList n) {
  //  n.child.accept(this);

  //  if(n.next !is null) {
  //    accum.put(", ");
  //    n.next.accept(this);
  //  }
  //}

  //override void visit(Join j) {
  //  if(j.lhs_node) {
  //    j.lhs_node.accept(this);
  //    accum.put(" ");
  //  }

  //  string join_str;
  //  final switch(j.type)
  //  with(Join.Type) {
  //    case Inner:     join_str = "INNER JOIN"; break;
  //    case LeftOuter: join_str = "LEFT OUTER JOIN"; break;
  //    case FullOuter: join_str = "FULL OUTER JOIN"; break;
  //    case Other:     join_str = j.join_str; break;
  //  }

  //  accum.put(join_str);
  //  accum.put(" ");
  //  accum.put(j.other_table_name);


  //  if(j.on) {
  //    accum.put(" ON ");
  //    j.on.accept(this);
  //  }
  //}

  //override void visit(ColWithOrder c) {
  //  c.col.accept(this);
  //  accum.put(" ");

  //  string dir_str;

  //  final switch(c.dir)
  //  with(ColWithOrder.Dir)
  //  {
  //    case Asc:   dir_str = "ASC"; break;
  //    case Desc:  dir_str = "DESC"; break;
  //    case Other: dir_str = c.dir_str; break;
  //  }

  //  accum.put(dir_str);
  //}

  void start_array() {
    accum.put("(");
  }
  void array_sep() {
    accum.put(", ");
  }
  void end_array() {
    accum.put(")");
  }

  void visit_lit(char c)  { visit_lit(cast(dchar) c); }
  void visit_lit(wchar w) { visit_lit(cast(dchar) w); }
  void visit_lit(dchar d) {
    accum.put('\'');
    // escape the individual char
    if(d == '\'')
    {
      accum.put('\\');
    }
    accum.put(d);
    accum.put('\'');
  }

  void visit_lit(int i) { visit_lit(cast(long) i); }
  void visit_lit(uint i) { visit_lit(cast(ulong) i); }
  void visit_lit(long  l) {
    import std.conv : to;
    accum.put(l.to!string);
  }
  void visit_lit(ulong u) {
    import std.conv : to;
    accum.put(u.to!string);
  }
  void visit_lit(const(char)[] str) {
    accum.put('"');

    // escape each character in the string
    foreach(s; str) {
      if(s == '"') {
        accum.put('\\');
      }
      accum.put(s);
    }

    accum.put('"');
  }
}
