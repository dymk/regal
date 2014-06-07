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

/// A node which can have 'and' and 'or' operators chained onto it
interface AndOrable : Node {
  AndOrable and(const WhereCondition and_cond) @safe pure nothrow const;
  AndOrable or(const WhereCondition or_cond) @safe pure nothrow const;
}

// template that provides a common implementation of AndOrable
package
mixin template AndOrableImpl() {
  final AndOrable and(const WhereCondition and_cond) @safe pure nothrow const
  {
    return new BinaryCompare(BinaryCompare.Op.And, this, and_cond);
  }
  final AndOrable or(const WhereCondition or_cond) @safe pure nothrow const {
    return new BinaryCompare(BinaryCompare.Op.Or, this, or_cond);
  }
}

/// A node which can be used as the constraint in a 'where' query
interface WhereCondition : Node {}

/// Node can have a `where` constraint applied to it
interface Whereable : Node {
  Where where(const WhereCondition) @safe pure nothrow const;
}

/// A node which can have the can have further specific limitations applied to
/// it. Despite the name, it includes limit, skip, group, and order
interface Limitable : Node {
  Limit limit(in int amt) @safe pure nothrow const;
  Skip   skip(in int amt) @safe pure nothrow const;
  Group group(const(WhereCondition)[] conds...) @safe pure nothrow const;
  Order order(const(WhereCondition)[] conds...) @safe pure nothrow const;
}

/// Pre-implemented Limitable interface that just wraps the caller
package
mixin template LimitableImpl() {
  final Limit limit(in int amt) @safe pure nothrow const {
    return new Limit(this, amt);
  }
  final Skip   skip(in int amt) @safe pure nothrow const {
    return new Skip(this, amt);
  }
  final Group group(const(WhereCondition)[] conds...) @safe pure nothrow const {
    return new Group(this, conds);
  }
  final Order order(const(WhereCondition)[] conds...) @safe pure nothrow const {
    return new Order(this, conds);
  }
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

  mixin AndOrableImpl;
  mixin AcceptVisitor;
}

/// A literal value node
class LitNode(T) : WhereCondition {
  T lit;

  this(T lit) @safe pure nothrow {
    this.lit = lit;
  }

  override void accept(Visitor v) const {
    import std.range : isInputRange;
    import std.traits : isSomeString, Unqual;
    static if(
      isInputRange!T &&
      !isSomeString!T) {

      // the lit is a range
      v.start_array();

      bool first = true;
      foreach(lit_elem; cast(Unqual!T) lit) {
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
      visit_nonrange_lit(v, cast(Unqual!T) lit);
    }
  }

  mixin AndOrableImpl;

private:
  static void visit_nonrange_lit(U)(Visitor v, in U l) {
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
