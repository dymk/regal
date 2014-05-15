module regal.table;

private {
  import regal;
  import std.stdio;
  import std.array;
  import std.exception;
}

class Table : Joinable {
private:
  ColNode[string] cols;
  string table_name;

public:
  this(string table, string[] cols_names...) {
    this.table_name = table;
    foreach(col; cols_names) {
      this.cols[col] = new ColNode(table_name, col);
    }
  }

  ColNode opDispatch(string col)() {
    return opIndex(col);
  }

  ColNode opIndex(string col) {
    enforce(col in cols, "`" ~ col ~ "` is not a column in `" ~ table ~ "`");
    return cols[col];
  }

  // For implementing CommonMethods
  string table() @property {
    return table_name;
  }

  Node this_as_lhs() {
    // tables themselves don't print
    return null;
  }
}
