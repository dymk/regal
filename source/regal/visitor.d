module regal.visitor;

private import regal;

interface Visitor {
  void visit(ColNode n);
  void visit(Sql s);
  void visit(BinOp n);
  void visit(Where n);
  void visit(Project p);
  void visit(NodeList n);
  void visit(Join j);
  void visit(ColWithOrder c);

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
