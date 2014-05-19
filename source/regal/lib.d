module regal.lib;

private import regal;

mixin template node_methods() {
  string to_sql() {
    scope a = appender!string();
    scope visitor = new MySqlPrinter!(Appender!string);
    visitor.run(this, a);
    return a.data();
  }
}

NodeList nodelist_from_arr(N)(N[] nodes) {
  NodeList root;
  foreach_reverse(node; nodes) {
    root = new NodeList(node, root);
  }
  return root;
}

template isClass(T) {
  enum isClass = is(T == class) || is(T == interface);
}

// Is 'name' a valid column in the Cols array?
template IsValidCol(string name, Cols...) {
  static if(Cols.length == 0) {
    enum IsValidCol = false;
  }
  else {
    static if(name == Cols[1]) {
      enum IsValidCol = true;
    }
    else {
      enum IsValidCol = IsValidCol!(name, Cols[2 .. $]);
    }
  }
}
