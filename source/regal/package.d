module regal;
private {
  import std.stdio;
  import std.array;
}

package {
  import regal.lib;
  import regal.visitor;
  import regal.ast;
  import regal.col_node;
}


interface ITable {
  final Where where(ClauseNode child) {
    return new Where(table, child, this_as_lhs());
  }

  final Join join(T)(T other_table, ClauseNode on = null)
  {
    return join(other_table.table, on);
  }
  final Join join(string other_table, ClauseNode on = null) {
    return new Join(table, other_table, on, this_as_lhs());
  }

  final Project project(Node[] projections...) {
    return project(nodelist_from_arr(projections));
  }
  final Project project(Node projection) {
    return new Project(table, projection, this_as_lhs());
  }

  final BinOp limit(int amt) {
    return new BinOp(
      table, BinOp.Kind.Limit,
      this_as_lhs(),
      new LitNodeImpl!int(table, amt));
  }

  final BinOp skip(int amt) {
    return new BinOp(
      table, BinOp.Kind.Skip,
      this_as_lhs(),
      new LitNodeImpl!int(table, amt));
  }

  final BinOp order(Node by) {
    return new BinOp(
      table, BinOp.Kind.Order,
      this_as_lhs(),
      by);
  }
  final BinOp order(Node[] by...) {
    return order(nodelist_from_arr(by));
  }

  final BinOp group(Node by) {
    return new BinOp(
      table, BinOp.Kind.Group,
      this_as_lhs(),
      by);
  }
  final BinOp group(Node[] by...) {
    return group(nodelist_from_arr(by));
  }

protected:
  string table() @property;
  Node this_as_lhs();
}

// Main API for regal
template Table(string _table_name, Args...)
{
  static assert(Args.length % 2 == 0, "uneven number of table args");

  // generates a single method for column 'name'
  string stringForCol(Type)(string name) {
    string ret;

    ret = q{
      private static ColNode colnode_%name% = null;
      auto %name%() {
        alias ColType = TypeForName!("%name%", Args);
        if(colnode_%name% is null) {
          colnode_%name% = new ColNode(_table_name, "%name%");
        }

        return colnode_%name%;
      }
    }.replace("%name%", name);

    return ret;
  }

  // Generates the getters for all the columns on the Table
  // class. E.g. for 'id':
  // class Table {
  //  auto id() { return Column!ColType(table_name, "id"); }
  // }
  string strForCols() {
    auto ret = "";
    foreach(i, Arg; Args) {
      static if(i % 2 == 0) { continue; }
      else {
        ret ~= stringForCol!(Args[i-1])(Args[i]);
      }
    }

    return ret;
  }

  pragma(msg, strForCols());

  class Table : ITable {
    mixin(strForCols());
    #line 60 "package.d"

    override string table() @property {
      return _table_name;
    }

    private Node _lhs_node = null;
    Node this_as_lhs() {
      if(_lhs_node is null) {
        _lhs_node = new NullNode();
      }

      return _lhs_node;
    }
  }
}
