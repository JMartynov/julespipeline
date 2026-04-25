"""
Main module for basic math operations and expression evaluation.
"""
import argparse
import ast
import json
import os


class DivisionByZeroError(Exception):
    """Custom exception raised for division by zero."""


def add(a, b):
    """Return the sum of a and b."""
    return a + b


def subtract(a, b):
    """Return the difference between a and b."""
    return a - b


def multiply(a, b):
    """Return the product of a and b."""
    return a * b


def divide(a, b):
    """Return the quotient of a and b."""
    if b == 0:
        raise DivisionByZeroError("Cannot divide by zero")
    return a / b


_OPERATORS = {
    ast.Add: add,
    ast.Sub: subtract,
    ast.Mult: multiply,
    ast.Div: divide,
    ast.USub: lambda x: subtract(0, x),
    ast.UAdd: lambda x: add(0, x),
}


_history = []


def get_history():
    """Return the calculation history."""
    return _history


def clear_history():
    """Clear the calculation history."""
    _history.clear()


def import_history(filepath: str):
    """Import calculation history from a JSON file.

    Validates that the JSON structure is a list of dictionaries
    with 'expression' and 'result' keys.
    """
    if os.path.isdir(filepath):
        raise IsADirectoryError(f"Is a directory: {filepath}")

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError as exc:
        raise FileNotFoundError(f"File not found: {filepath}") from exc
    except json.JSONDecodeError as exc:
        raise ValueError("Invalid JSON format") from exc

    if not isinstance(data, list):
        raise ValueError("Invalid history format: expected a list")

    for item in data:
        if not isinstance(item, dict):
            raise ValueError("Invalid history entry: expected a dictionary")
        if 'expression' not in item or 'result' not in item:
            raise ValueError(
                "Invalid history entry: missing 'expression' or 'result' keys"
            )

    _history.extend(data)


def evaluate_expression(expression: str):
    """Parse and evaluate a mathematical expression from a string."""
    try:
        node = ast.parse(expression, mode='eval')
        result = _eval_node(node.body)
        _history.append({"expression": expression, "result": result})
        return result
    except SyntaxError as exc:
        msg = f"Invalid syntax in expression: {expression}"
        raise ValueError(msg) from exc


def _eval_node(node):
    """Recursively evaluate an AST node."""
    if isinstance(node, ast.Constant):
        return node.value

    if isinstance(node, ast.BinOp):
        left = _eval_node(node.left)
        right = _eval_node(node.right)
        op_type = type(node.op)
        if op_type in _OPERATORS:
            return _OPERATORS[op_type](left, right)
        raise ValueError(f"Unsupported operator: {op_type}")

    if isinstance(node, ast.UnaryOp):
        operand = _eval_node(node.operand)
        op_type = type(node.op)
        if op_type in _OPERATORS:
            return _OPERATORS[op_type](operand)
        raise ValueError(f"Unsupported unary operator: {op_type}")

    raise ValueError(f"Unsupported expression node: {type(node)}")


def main():
    """Main entry point for the CLI."""
    parser = argparse.ArgumentParser(
        description="Evaluate mathematical expressions."
    )
    parser.add_argument(
        "expression",
        nargs="?",
        help="The mathematical expression to evaluate."
    )
    parser.add_argument(
        "--import-history",
        dest="history_file",
        help="Path to a JSON file to import calculation history from."
    )

    args = parser.parse_args()

    if args.history_file:
        try:
            import_history(args.history_file)
            print(f"Successfully imported history from {args.history_file}")
        except (ValueError, OSError) as exc:
            print(f"Error importing history: {exc}")

    if args.expression:
        try:
            result = evaluate_expression(args.expression)
            print(f"Result: {result}")
        except (ValueError, DivisionByZeroError) as exc:
            print(f"Error evaluating expression: {exc}")


if __name__ == "__main__":
    main()
