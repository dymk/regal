module regal.joinable;

private import regal;

interface Joinable : CommonMethods {
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
}
