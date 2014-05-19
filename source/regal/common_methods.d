module regal.common_methods;

private import regal;

/*
 * Methods common to nodes directly accessable to the user
 */
mixin template common_methods() {

  final BinOp limit(int amt) {
  return new BinOp(
    table, BinOp.Kind.Limit,
    this_as_lhs(),
    new LitNode!int(table, amt));
  }

  final BinOp skip(int amt) {
    return new BinOp(
      table, BinOp.Kind.Skip,
      this_as_lhs(),
      new LitNode!int(table, amt));
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

  final Project project(N)(N[] projections...) {
    return project(nodelist_from_arr(projections));
  }
  final Project project(Node projection) {
    return new Project(table, projection, this_as_lhs());
  }

  // ensure the thing this is mixed into responds to these methods
  //static assert(__traits(compiles, {
  //  string table_name = this.table;
  //}));

  //static assert(__traits(compiles, {
  //  Node talhs = this.this_as_lhs();
  //}));
}
