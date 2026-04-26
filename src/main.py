# Validated Remote Workflow
"""
Main module for basic math operations and expression evaluation.
"""
import ast
import decimal


class CalculatorConfig:  # pylint: disable=too-few-public-methods
    """Configuration for the calculator."""
    use_decimal = False


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


def evaluate_expression(expression: str):
    """Parse and evaluate a mathematical expression from a string."""
    try:
        node = ast.parse(expression, mode='eval')
        return _eval_node(node.body, expression)
    except SyntaxError as exc:
        msg = f"Invalid syntax in expression: {expression}"
        raise ValueError(msg) from exc


def _eval_node(node, expression: str):
    """Recursively evaluate an AST node."""
    if isinstance(node, ast.Constant):
        if CalculatorConfig.use_decimal and isinstance(
                node.value, (int, float)) and not isinstance(node.value, bool):
            # Extract high-precision string if possible
            source_str = ast.get_source_segment(expression, node)
            if source_str is not None:
                return decimal.Decimal(source_str)
            return decimal.Decimal(str(node.value))
        return node.value

    if isinstance(node, ast.BinOp):
        left = _eval_node(node.left, expression)
        right = _eval_node(node.right, expression)
        op_type = type(node.op)
        if op_type in _OPERATORS:
            return _OPERATORS[op_type](left, right)
        raise ValueError(f"Unsupported operator: {op_type}")

    if isinstance(node, ast.UnaryOp):
        operand = _eval_node(node.operand, expression)
        op_type = type(node.op)
        if op_type in _OPERATORS:
            return _OPERATORS[op_type](operand)
        raise ValueError(f"Unsupported unary operator: {op_type}")

    raise ValueError(f"Unsupported expression node: {type(node)}")


if __name__ == "__main__":  # pragma: no cover
    print(f"Result: {add(1, 2)}")
