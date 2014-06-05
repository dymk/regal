module regal.visitor;

private import regal;

interface Visitor {
  void visit(const Sql);
  void visit(const BinaryCompare);

  void visit(const Select);
  void visit(const Where);

  void visit(const Limit);
  void visit(const Skip);
  void visit(const Group);
  void visit(const Order);

  void visit(const Table);
  void visit(const JoinedTable);
  void visit(const AsTable);

  void visit(const UnorderedColumn);
  void visit(const OrderedColumn);
  void visit(const AsColumn);

  // Handles printing literals held in a LitNode!T
  void start_array();
  void array_sep();
  void end_array();

  void visit_lit(dchar  d);
  void visit_lit(wchar  d);
  void visit_lit(char  d);
  void visit_lit(long  l);
  void visit_lit(ulong u);
  void visit_lit(int  l);
  void visit_lit(uint u);
  void visit_lit(const(char)[] s);
}
