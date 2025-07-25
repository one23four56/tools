// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:meta/meta.dart';

import '../base.dart';
import 'code.dart';
import 'expression.dart';
import 'reference.dart';

part 'control.g.dart';

/// Root class for control-flow blocks.
///
/// {@category controlFlow}
@internal
@immutable
abstract mixin class ControlBlock implements Code, Spec {
  /// The full control-flow expression that precedes this block.
  ControlExpression get _expression;

  /// The body of this block.
  ///
  /// *Note: will always be wrapped in `{`braces`}`*.
  Block get body;

  @override
  R accept<R>(covariant ControlBlockVisitor<R> visitor, [R? context]) =>
      visitor.visitControlBlock(this, context);
}

/// Adds label support to a [ControlBlock].
///
/// {@category controlFlow}
@internal
mixin LabeledControlBlock on ControlBlock {
  /// An (optional) label for this block.
  ///
  /// ```dart
  /// label: {block}
  /// ```
  ///
  /// https://dart.dev/language/loops#labels
  String? get label;

  @override
  R accept<R>(covariant ControlBlockVisitor<R> visitor, [R? context]) =>
      visitor.visitLabeledBlock(this);
}

// abstract mixin class ControlTree

/// Represents a traditional `for` loop.
///
/// ```dart
/// for (initialize; condition; advance) {
///   body
/// }
/// ```
///
/// https://dart.dev/language/loops#for-loops
///
/// {@category controlFlow}
abstract class ForLoop
    with ControlBlock, LabeledControlBlock
    implements Built<ForLoop, ForLoopBuilder> {
  ForLoop._();

  /// The initializer expression.
  ///
  /// Leave `null` to omit.
  Expression? get initialize;

  /// The for loop condition.
  ///
  /// Leave `null` to omit.
  Expression? get condition;

  /// The advancer expression.
  ///
  /// Leave `null` to omit.
  Expression? get advance;

  @override
  ControlExpression get _expression =>
      ControlExpression.forLoop(initialize, condition, advance);

  factory ForLoop(void Function(ForLoopBuilder loop) builder) = _$ForLoop;
}

/// Represents a `for-in` loop.
///
/// ```dart
/// for (variable in object) {
///   body
/// }
/// ```
///
/// If [async] is `true`, the loop will be asynchronous (`await for`):
/// ```dart
/// await for (variable in object) {
///   body
/// }
/// ```
///
/// https://dart.dev/language/loops#for-loops
///
/// {@category controlFlow}
abstract class ForInLoop
    with ControlBlock, LabeledControlBlock
    implements Built<ForInLoop, ForInLoopBuilder> {
  ForInLoop._();
  factory ForInLoop(void Function(ForInLoopBuilder loop) builder) = _$ForInLoop;

  /// Whether or not this is an asynchronous (`await for`) loop.
  bool? get async;

  /// The iterated variable (before `in`).
  Expression get variable;

  /// The object being iterated on (after `in`).
  Expression get object;

  @override
  ControlExpression get _expression => async == true
      ? ControlExpression.awaitForLoop(variable, object)
      : ControlExpression.forInLoop(variable, object);
}

/// Represents a `while` loop.
///
/// ```dart
/// while (condition) {
///   body
/// }
/// ```
///
/// If [doWhile] is `true`, the loop will be in the `do-while` format:
/// ```dart
/// do {
///   body
/// } while (condition);
/// ```
///
/// https://dart.dev/language/loops#while-and-do-while
///
/// {@category controlFlow}
abstract class WhileLoop
    with ControlBlock, LabeledControlBlock
    implements Built<WhileLoop, WhileLoopBuilder> {
  WhileLoop._();
  factory WhileLoop(void Function(WhileLoopBuilder loop) builder) = _$WhileLoop;

  /// Whether or not this is a `do-while` loop.
  bool? get doWhile;

  /// The loop condition.
  Expression get condition;

  /// Always returns the `while` statement, regardless
  /// of the value of [doWhile].
  ControlExpression get _statement => ControlExpression.whileLoop(condition);

  @override
  ControlExpression get _expression =>
      doWhile == true ? ControlExpression.doStatement : _statement;

  @override
  R accept<R>(covariant ControlBlockVisitor<R> visitor, [R? context]) =>
      visitor.visitWhileLoop(this, context);
}

/// A tree of [ControlBlock]s
@internal
@immutable
abstract mixin class ControlTree implements Code, Spec {
  /// The items in this tree.
  List<ControlBlock?> get _blocks;

  @override
  R accept<R>(covariant ControlBlockVisitor<R> visitor, [R? context]) =>
      visitor.visitControlTree(this, context);
}

/// Represents a single `if` block.
///
/// Use [IfTree] to create a tree of `if`, `else if`,
/// and `else` statements.
///
/// {@category controlFlow}
abstract class Condition
    with ControlBlock
    implements Built<Condition, ConditionBuilder> {
  Condition._();
  factory Condition(void Function(ConditionBuilder block) builder) =
      _$Condition;

  /// The statement condition.
  ///
  /// Required if this is a standalone [Condition] or
  /// the first in an [IfTree], otherwise optional.
  Expression? get condition;

  ControlExpression? get _statement =>
      condition == null ? null : ControlExpression.ifStatement(condition!);

  @override
  ControlExpression get _expression =>
      _statement ??
      (throw ArgumentError(
          'A condition must be provided with an `if` statement', 'condition'));

  /// This condition as an `else` block.
  ///
  /// Will be `else` if [condition] is `null`,
  /// otherwise `else if`.
  Condition get asElse => ElseCondition(this);

  /// Returns an [IfTree] with just this [Condition].
  IfTree get asTree => IfTree.of([this]);
}

/// Builds a [Condition].
///
/// {@category controlFlow}
abstract class ConditionBuilder
    implements Builder<Condition, ConditionBuilder> {
  ConditionBuilder._();
  factory ConditionBuilder() = _$ConditionBuilder;

  BlockBuilder body = BlockBuilder();
  Expression? condition;

  /// Sets [condition] to an `if-case` expression.
  ///
  /// Uses [ControlFlow.ifCase] to create the expression.
  ///
  /// The expression will take the form:
  /// ```dart
  /// object case pattern
  /// ```
  ///
  /// Optionally set a guard (`when`) clause with [guard]:
  /// ```dart
  /// object case pattern when guard
  /// ```
  ///
  /// See https://dart.dev/language/branches#if-case
  void ifCase({
    required Expression object,
    required Expression pattern,
    Expression? guard,
  }) {
    condition =
        ControlFlow.ifCase(object: object, pattern: pattern, guard: guard);
  }
}

/// A [condition] preceded by `else`
@internal
@visibleForTesting
class ElseCondition extends _$Condition {
  ElseCondition(Condition condition)
      : super._(body: condition.body, condition: condition.condition);

  @override
  ControlExpression get _expression =>
      ControlExpression.elseStatement(_statement);
}

/// Represents an `if`/`else` tree.
///
/// The first [Condition]  in [blocks] will be treated as an `if`
/// block. All subsequent conditions will be treated as `else` blocks
/// using [Condition.asElse].
///
/// {@category controlFlow}
abstract class IfTree with ControlTree implements Built<IfTree, IfTreeBuilder> {
  IfTree._();

  /// Build an [IfTree]
  factory IfTree(void Function(IfTreeBuilder tree) builder) = _$IfTree;

  /// Create an [IfTree] from a list of [conditions].
  factory IfTree.of(Iterable<Condition> conditions) => IfTree(
        (tree) {
          tree.addAll(conditions);
        },
      );

  /// Called when an [IfTreeBuilder] is built.
  ///
  /// Replaces all but the first block with an [ElseCondition]
  ///
  @BuiltValueHook(finalizeBuilder: true)
  static void _build(IfTreeBuilder builder) {
    if (builder.blocks.isEmpty) return;

    final first = builder.blocks.first;
    builder.blocks
      ..skip(1)
      ..map((b) => b.asElse)
      ..insert(0, first);
  }

  BuiltList<Condition> get blocks;

  @override
  List<ControlBlock> get _blocks => blocks.toList();

  /// Returns a new [IfTree] with [condition] added.
  IfTree withCondition(Condition condition) =>
      (toBuilder()..add(condition)).build();

  /// Builds a [Condition] with [builder] and returns
  /// a new [IfTree] with it added.
  IfTree elseIf(void Function(ConditionBuilder block) builder) =>
      withCondition((ConditionBuilder()..update(builder)).build());

  /// Builds a block with [builder] and returns a new [IfTree]
  /// with it added as an `else` [Condition].
  IfTree orElse(void Function(BlockBuilder body) builder) => elseIf(
        (block) {
          builder(block.body);
        },
      );
}

/// Builds an [IfTree].
///
/// {@category controlFlow}
abstract class IfTreeBuilder implements Builder<IfTree, IfTreeBuilder> {
  IfTreeBuilder._();
  factory IfTreeBuilder() = _$IfTreeBuilder;

  /// The items in this tree.
  ListBuilder<Condition> blocks = ListBuilder();

  /// Build a [Condition] with [builder] and add it to the tree.
  ///
  /// Shorthand for calling `add` and creating a condition
  void ifThen(void Function(ConditionBuilder block) builder) =>
      add((ConditionBuilder()..update(builder)).build());

  /// Add a [Condition] to the tree.
  ///
  /// Shorthand for `blocks.add`
  void add(Condition condition) => blocks.add(condition);

  /// Add multiple [Condition]s to the tree.
  ///
  /// Shorthand for `blocks.addAll`
  void addAll(Iterable<Condition> conditions) => blocks.addAll(conditions);

  /// Builds a block using [builder] and adds it to the tree
  /// as an `else` [Condition].
  ///
  /// Shorthand for calling [add] and creating an `else` condition.
  void orElse(void Function(BlockBuilder body) builder) => add(Condition(
        (block) {
          builder(block.body);
        },
      ));

  /// Shorthand to add an `else` statement that throws [expression].
  void orElseThrow(Expression expression) => orElse(
        (body) {
          body.addExpression(expression.thrown);
        },
      );
}

/// Represents a `catch` block.
///
/// {@category controlFlow}
abstract class CatchBlock
    with ControlBlock
    implements Built<CatchBlock, CatchBlockBuilder> {
  CatchBlock._();
  factory CatchBlock([void Function(CatchBlockBuilder) updates]) = _$CatchBlock;

  /// The optional type of exception to catch (`on` clause).
  ///
  /// ``` dart
  /// on type catch (exception)
  /// on type catch (exception, stacktrace)
  /// ```
  Reference? get type;

  /// The name of the exception parameter (default: `e`).
  ///
  /// ```dart
  /// catch (exception)
  /// catch (exception, stacktrace)
  /// ```
  String get exception;

  /// The optional name of the stacktrace parameter.
  ///
  /// Will be excluded if left `null`.
  ///
  /// ```dart
  /// catch (exception)
  /// catch (exception, stacktrace)
  /// ```
  String? get stacktrace;

  ControlExpression get _catch =>
      ControlExpression.catchStatement(exception, stacktrace);

  @override
  ControlExpression get _expression =>
      type == null ? _catch : ControlExpression.onStatement(type!, _catch);

  /// Set the default value of [exception]
  @BuiltValueHook(initializeBuilder: true)
  static void _initialize(CatchBlockBuilder builder) => builder.exception = 'e';
}

/// Represents a `try` or `finally` block.
///
/// **INTERNAL ONLY**.
@internal
class TryBlock with ControlBlock {
  @override
  final Block body;
  final bool isFinally;

  const TryBlock._(this.body) : isFinally = false;
  const TryBlock._finally(this.body) : isFinally = true;

  @override
  ControlExpression get _expression => isFinally
      ? ControlExpression.finallyStatement
      : ControlExpression.tryStatement;
}

/// Represents a `try`/`catch` block.
///
/// {@category controlFlow}
abstract class TryCatch
    with ControlTree
    implements Built<TryCatch, TryCatchBuilder> {
  TryCatch._();

  /// Build a [TryCatch].
  factory TryCatch([void Function(TryCatchBuilder) updates]) = _$TryCatch;

  /// The body of the `try` clause.
  ///
  /// ```dart
  /// try {
  ///   body
  /// }
  /// ```
  Block get body;

  /// The `catch` clauses for this block.
  BuiltList<CatchBlock> get handlers;

  /// The optional `finally` clause body.
  ///
  /// ```dart
  /// finally {
  ///   handleAll
  /// }
  /// ```
  Block? get handleAll;

  TryBlock get _try => TryBlock._(body);
  TryBlock? get _finally =>
      handleAll == null ? null : TryBlock._finally(handleAll!);

  @override
  List<ControlBlock?> get _blocks => [_try, ...handlers, _finally];

  /// Ensure [handlers] is not empty
  @BuiltValueHook(finalizeBuilder: true)
  static void _build(TryCatchBuilder builder) =>
      builder.handlers.isNotEmpty ||
      (throw ArgumentError(
          'One or more `catch` clauses must be specified.', 'handlers'));
}

/// Builds a [TryCatch] block.
///
/// {@category controlFlow}
abstract class TryCatchBuilder implements Builder<TryCatch, TryCatchBuilder> {
  TryCatchBuilder._();
  factory TryCatchBuilder() = _$TryCatchBuilder;

  /// The body of the `try` clause.
  ///
  /// ```dart
  /// try {
  ///   body
  /// }
  /// ```
  BlockBuilder body = BlockBuilder();

  /// The optional `finally` clause body.
  ///
  /// ```dart
  /// finally {
  ///   handleAll
  /// }
  /// ```
  BlockBuilder? handleAll;

  /// The `catch` clauses for this block.
  ListBuilder<CatchBlock> handlers = ListBuilder();

  /// Build a `catch` clause and add it to [handlers].
  void addCatch(void Function(CatchBlockBuilder block) builder) =>
      handlers.add((CatchBlockBuilder()..update(builder)).build());

  /// Build a `finally` clause and update [handleAll].
  void addFinally(void Function(BlockBuilder body) builder) =>
      handleAll = BlockBuilder()..update(builder);
}

/// Knowledge of different types of control blocks.
///
@internal
abstract class ControlBlockVisitor<T>
    implements ExpressionVisitor<T>, CodeVisitor<T> {
  T visitControlBlock(ControlBlock block, [T? context]);
  T visitLabeledBlock(LabeledControlBlock block, [T? context]);
  T visitWhileLoop(WhileLoop loop, [T? context]);
  T visitControlTree(ControlTree tree, [T? context]);
  T visitControlExpression(ControlExpression expression, [T? context]);
}

/// Knowledge of how to write valid Dart code from [ControlBlockVisitor].
///
@internal
abstract mixin class ControlBlockEmitter
    implements ControlBlockVisitor<StringSink> {
  @override
  StringSink visitControlBlock(ControlBlock block, [StringSink? output]) {
    output ??= StringBuffer();
    block._expression.accept(this, output);
    output.write(' { ');
    block.body.accept(this, output);
    output.write(' }');
    return output;
  }

  @override
  StringSink visitLabeledBlock(LabeledControlBlock block,
      [StringSink? output]) {
    output ??= StringBuffer();
    if (block.label != null) {
      output.write('${block.label!}: ');
    }

    return visitControlBlock(block, output);
  }

  @override
  StringSink visitWhileLoop(WhileLoop loop, [StringSink? output]) {
    output ??= StringBuffer();
    visitLabeledBlock(loop, output);

    if (loop.doWhile != true) return output;

    output.write(' ');
    loop._statement.statement.accept(this, output);
    return output;
  }

  @override
  StringSink visitControlTree(ControlTree tree, [StringSink? output]) {
    output ??= StringBuffer();

    for (final item in tree._blocks.nonNulls) {
      item.accept(this, output);
      output.write(' ');
    }

    return output;
  }

  @override
  StringSink visitControlExpression(ControlExpression expression,
      [StringSink? output]) {
    output ??= StringBuffer();

    output.write(expression.control);

    if (expression.body == null || expression.body!.isEmpty) {
      return output;
    }

    final body = expression.body!; // convenience

    output.write(' ');
    if (expression.parenthesised) {
      output.write('(');
    }

    if (body.length == 1) {
      body.first?.accept(this, output);
      if (expression.parenthesised) {
        output.write(')');
      }

      return output;
    }

    if (expression.separator == null) {
      throw ArgumentError(
          'A separator must be provided when body contains '
              'multiple expressions.',
          'separator');
    }

    final separator = expression.separator!; // convenience

    for (var i = 0; i < body.length; i++) {
      final expression = body[i];

      if (i != 0 && expression != null) {
        output.write(' ');
      }

      expression?.accept(this, output);

      if (i == body.length - 1) continue; // no separator after last item

      output.write(separator);
    }

    if (expression.parenthesised) {
      output.write(')');
    }

    return output;
  }
}
