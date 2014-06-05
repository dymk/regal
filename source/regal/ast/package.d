module regal.ast;

package {
  import regal;
}

public {
  import regal.ast.table;
  import regal.ast.column;
  import regal.ast.select;
  //import regal.ast.insert;
  //import regal.ast.update;
  //import regal.ast._delete;
}

/// Root class for all AST nodes
interface Node {
  void accept(Visitor v) const;
}

// Helper mixin for accepting a visitor
package
mixin template AcceptVisitor() {
  override void accept(Visitor v) const {
    v.visit(this);
  }
}
package
mixin template AcceptVisitor2() {
  void accept(Visitor v) const {
    v.visit(this);
  }
}

/// A node which can be used as the constraint in a 'where' query
interface WhereCondition : Node {}

/// Node can have a `where` constraint applied to it
interface Whereable : Node {
  Where where(const WhereCondition) const;
}

/// A node which can have the can have further specific limitations applied to
/// it. Despite the name, it includes limit, skip, group, and order
interface Limitable : Node {
  // TODO: implement these
  final Limit limit(in int amt) @safe pure nothrow const;
  final Skip   skip(in int amt) @safe pure nothrow const;
  final Group group(const(WhereCondition)[] conds...) @safe pure nothrow const;
  final Order order(const(WhereCondition)[] conds...) @safe pure nothrow const;
}

/// A literal SQL string, inserted into the query verbatim
final class Sql : WhereCondition {
  const string sql;

  this(const string sql) @safe pure nothrow {
    this.sql = sql;
  }

  static Sql opCall(const string sql) @safe pure nothrow {
    return new Sql(sql);
  }

  mixin AcceptVisitor;
}

/// A literal value node
class LitNode(T) : WhereCondition {
  const T lit;

  this(ref T lit) @safe pure nothrow {
    this.lit = lit;
  }

  override void accept(Visitor v) const {
    import std.range : isInputRange;
    import std.traits : isSomeString;
    static if(
      isInputRange!T &&
      !isSomeString!T) {

      // the lit is a range
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

  mixin AcceptVisitor;

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
