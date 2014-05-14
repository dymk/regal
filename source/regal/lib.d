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

//template isCol(T) {
//  enum isCol = is(T == Column!U, U);
//}

//static assert(isCol!(Column!int));

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

// Evaluates to the column type for 'name'
template TypeForName(string name, Cols...){
  static if(Cols.length == 0) {
    alias TypeForName = void;
  }
  else {
    static if(name == Cols[1]) {
      alias TypeForName = Cols[0];
    }
    else {
      alias TypeForName = TypeForName!(name, Cols[2 .. $]);
    }
  }
}
