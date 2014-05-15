module regal.lib;

private import regal;

NodeList nodelist_from_arr(Node[] nodes) {
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
