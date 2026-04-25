"""
Main module for basic math operations and expression evaluation.
"""
import ast
import math


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


def power(a, b):
    """Return a raised to the power of b."""
    return a ** b


def sqrt(a):
    """Return the square root of a."""
    if a < 0:
        raise ValueError("Cannot calculate square root of a negative number")
    return math.sqrt(a)


def log(a, base=math.e):
    """Return the logarithm of a with the given base."""
    if a <= 0:
        raise ValueError("Cannot calculate logarithm of a non-positive number")
    if base <= 0 or base == 1:
        raise ValueError("Logarithm base must be positive and not equal to 1")
    return math.log(a, base)


_OPERATORS = {
    ast.Add: add,
    ast.Sub: subtract,
    ast.Mult: multiply,
    ast.Div: divide,
    ast.Pow: power,
    ast.USub: lambda x: subtract(0, x),
    ast.UAdd: lambda x: add(0, x),
}


def evaluate_expression(expression: str):
    """Parse and evaluate a mathematical expression from a string."""
    try:
        node = ast.parse(expression, mode='eval')
        return _eval_node(node.body)
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

    if isinstance(node, ast.Call):
        if isinstance(node.func, ast.Name):
            func_name = node.func.id
            args = [_eval_node(arg) for arg in node.args]
            if func_name == "sqrt":
                if len(args) != 1:
                    raise ValueError("sqrt expects exactly 1 argument")
                return sqrt(args[0])
            if func_name == "log":
                if len(args) not in (1, 2):
                    raise ValueError("log expects 1 or 2 arguments")
                return log(*args)
        raise ValueError(f"Unsupported function call: {node.func}")

    raise ValueError(f"Unsupported expression node: {type(node)}")


if __name__ == "__main__":
    print(f"Result: {add(1, 2)}")
