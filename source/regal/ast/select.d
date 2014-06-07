module regal.ast.select;

private import regal.ast;

// Binary comparison between two where conditions,
// can be used as a clause in a Where query. For instance, two
// columns compared against each other, or a column vs a primitive
final class BinaryCompare : WhereCondition, AndOrable {
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

  mixin AndOrableImpl;
  mixin AcceptVisitor;
}

class Where : Whereable, AndOrable {
  const Whereable      left; // lhs
  const WhereCondition cond; // rhs

  /// forward chained 'where' to 'and'
  Where where(const WhereCondition and_cond) @safe pure nothrow const
  {
    return and(and_cond);
  }
  Where and(const WhereCondition and_cond) @safe pure nothrow const
  {
    return op_impl!Where(BinaryCompare.Op.And, and_cond);
  }
  Where or(const WhereCondition or_cond) @safe pure nothrow const
  {
    return op_impl!Where(BinaryCompare.Op.Or, or_cond);
  }

  this(const Whereable left, const WhereCondition condition) @safe pure nothrow
  {
    this.left = left;
    this.cond = condition;
  }

protected:
  WhereType op_impl(WhereType)(in BinaryCompare.Op for_op, const WhereCondition other)
  @trusted pure nothrow const
  {
    auto binop = new BinaryCompare(for_op, cond, other);
    return new WhereType(left, binop);
  }

public:
  mixin AcceptVisitor;
}

final class SelectWhere : Where, Limitable {
  this(const Whereable left, const WhereCondition condition)
  @safe pure nothrow {
    super(left, condition);
  }

  /// Must override these methods from class Where
  override
  SelectWhere where(const WhereCondition and_cond) @safe pure nothrow const
  {
    return and(and_cond);
  }
  override
  SelectWhere and(const WhereCondition and_cond) @safe pure nothrow const
  {
    return op_impl!SelectWhere(BinaryCompare.Op.And, and_cond);
  }
  override
  SelectWhere or(const WhereCondition or_cond) @safe pure nothrow const
  {
    return op_impl!SelectWhere(BinaryCompare.Op.Or, or_cond);
  }

  mixin LimitableImpl;
}

/// SELECT <projection> FROM <table> part of the query
final class Select : Whereable, Limitable {

  const ATable  table;
  const(WhereCondition)[] projection;

  this(const ATable table, const WhereCondition[] projection) @safe pure nothrow {
    // workaround for LDC bug (might also exist in DMD)
    const(WhereCondition)[] _projection;
    foreach(p; projection) {
      _projection ~= p;
    }

    this.projection = _projection;
    this.table = table;
  }

  override
  SelectWhere where(const WhereCondition condition)
  @safe pure nothrow const
  {
    return new SelectWhere(this, condition);
  }

  mixin LimitableImpl;
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

  mixin LimitableImpl;
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

  mixin LimitableImpl;
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
