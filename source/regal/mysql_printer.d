module regal.mysql_printer;

private {
  import regal;
  import std.range;
  import std.conv;
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
    //accum.put("`");
    accum.put(n.table);
    accum.put(".");
    //accum.put("`.`");
    accum.put(n.col);
    //accum.put("`");
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

      case In:    opstr = " IN ";         break;
      case NotIn: opstr = " NOT IN ";     break;
      case Like:    opstr = " LIKE ";     break;
      case NotLike: opstr = " NOT LIKE "; break;
      case As:      opstr = " AS ";       break;

      case And: opstr = " AND "; break;
      case Or:  opstr = " OR ";  break;

      case Limit: opstr = " LIMIT ";    add_parens = false; break;
      case Skip:  opstr = " SKIP ";     add_parens = false; break;
      case Group: opstr = " GROUP BY "; add_parens = false; break;
      case Order: opstr = " ORDER BY "; add_parens = false; break;
    }

    if(add_parens) accum.put("(");
    b.lhs !is null && b.lhs.accept(this);

    accum.put(opstr);

    b.rhs !is null && b.rhs.accept(this);
    if(add_parens) accum.put(")");
  }

  override void visit(Where w) {
    if(w.lhs) {
      w.lhs.accept(this);
      accum.put(" ");
    }

    accum.put("WHERE ");
    w.child.accept(this);
  }

  override void visit(Project s) {
    accum.put("SELECT ");
    s.projection.accept(this);
    accum.put(" FROM ");

    accum.put(s.table);

    if(s.clause) {
      accum.put(" ");
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

  override void visit(Join j) {
    if(j.lhs_node !is null) {
      j.lhs_node.accept(this);
      accum.put(" ");
    }

    string join_str;
    final switch(j.type)
    with(Join.Type) {
      case Inner:     join_str = "INNER JOIN"; break;
      case LeftOuter: join_str = "LEFT OUTER JOIN"; break;
      case FullOuter: join_str = "FULL OUTER JOIN"; break;
      case Other:     join_str = j.join_str; break;
    }

    accum.put(join_str);
    accum.put(" ");
    accum.put(j.other_table_name);


    if(j.on) {
      accum.put(" ON ");
      j.on.accept(this);
    }
  }

  override void visit(ColWithOrder c) {
    c.col.accept(this);
    accum.put(" ");

    string dir_str;

    final switch(c.dir)
    with(ColWithOrder.Dir)
    {
      case Asc:   dir_str = "ASC"; break;
      case Desc:  dir_str = "DESC"; break;
      case Other: dir_str = c.dir_str; break;
    }

    accum.put(dir_str);
  }

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
