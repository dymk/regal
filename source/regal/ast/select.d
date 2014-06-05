module regal.ast.select;

private import regal.ast;

// Binary comparison between two where conditions,
// can be used as a clause in a Where query. For instance, two
// columns compared against each other, or a column vs a primitive
final class BinaryCompare : WhereCondition {
  enum Op {
    And, Or,
    Eq, Ne,
    Lt, Lte,
    Gt, Gte,
    In, NotIn,
    Like, NotLike,
  }

  const Op op;
  const WhereCondition left;
  const WhereCondition right;

  this(const Op op, const(WhereCondition) left, const(WhereCondition) right)
  @safe pure nothrow
  {
    this.op = op;
    this.left = left;
    this.right = right;
  }

  mixin AcceptVisitor;
}

class Where : Whereable {
  const Whereable      left; // lhs
  const WhereCondition cond; // rhs

  /// forward chained 'where' to 'and'
  Where where(inout WhereCondition and_cond) @safe pure nothrow inout
  {
    return and(and_cond);
  }
  Where and(inout WhereCondition and_cond) @safe pure nothrow inout
  {
    return op_impl!Where(BinaryCompare.Op.And, and_cond);
  }
  Where or(inout WhereCondition or_cond) @safe pure nothrow inout
  {
    return op_impl!Where(BinaryCompare.Op.Or, or_cond);
  }

  this(const Whereable left, const WhereCondition condition) @safe pure nothrow
  {
    this.left = left;
    this.cond = condition;
  }

protected:
  WhereType op_impl(WhereType : Where)(in BinaryCompare.Op for_op, inout WhereCondition other)
  @trusted pure nothrow inout
  {
    auto binop = new BinaryCompare(for_op, cond, other);
    return new WhereType(left, binop);
  }

public:
  mixin AcceptVisitor;
}

final class SelectWhere : Where, Limitable {
  /// Must override these methods from class Where
  override
  SelectWhere where(inout WhereCondition and_cond) @safe pure nothrow inout
  {
    return and(and_cond);
  }
  override
  SelectWhere and(inout WhereCondition and_cond) @safe pure nothrow inout
  {
    return op_impl!SelectWhere(BinaryCompare.Op.And, and_cond);
  }
  override
  SelectWhere or(inout WhereCondition or_cond) @safe pure nothrow inout
  {
    return op_impl!SelectWhere(BinaryCompare.Op.Or, or_cond);
  }

  this(const Whereable left, const WhereCondition condition)
  @safe pure nothrow {
    super(left, condition);
  }
}

/// SELECT <projection> FROM <table> part of the query
final class Select : Whereable, Limitable {
  const ATable  table;
  const Node[] projection;

  this(const ATable table, const Node[] projection...) @safe pure nothrow {
    this.projection = projection;
    this.table = table;
  }

  override
  SelectWhere where(inout WhereCondition condition)
  @safe pure nothrow inout
  {
    return new SelectWhere(this, condition);
  }

  mixin AcceptVisitor;
}

// Implementation of the Limitable return types
private
mixin template LimitSelectBase() {
  const Limitable root;
  const int amt;

  this(const Limitable root, in int amt) @safe pure nothrow {
    this.root = root;
    this.amt = amt;
  }

  mixin AcceptVisitor2;
}

private
mixin template GroupOrderBase() {
  const Limitable root;
  const(WhereCondition)[] conds;

  this(const Limitable root, const(WhereCondition)[] conds...)
  @safe pure nothrow
  {
    this.root = root;
    this.conds = conds;
  }

  mixin AcceptVisitor2;
}

final class Limit : Limitable {
  mixin LimitSelectBase;
}
final class Skip : Limitable {
  mixin LimitSelectBase;
}
final class Group : Limitable {
  mixin GroupOrderBase;
}
final class Order : Limitable {
  mixin GroupOrderBase;
}
