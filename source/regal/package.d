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

// Main API for regal
template Table(string table_name, Args...)
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
          colnode_%name% = new ColNode(table_name, "%name%");
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

  class Table {
    mixin(strForCols());
    #line 53 "package.d"

    Where where(Node child) {
      return new Where(table_name, child);
    }

    Project project(Node[] projections...) {
      return project(nodelist_from_arr(projections));
    }
    Project project(Node projection) {
      return new Project(table_name, projection, null);
    }
  }
}
