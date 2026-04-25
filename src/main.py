import ast


class DivisionByZeroError(Exception):
    """Custom exception raised for division by zero."""
    pass


def add(a, b):
    return a + b


def subtract(a, b):
    return a - b


def multiply(a, b):
    return a * b


def divide(a, b):
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
    try:
        node = ast.parse(expression, mode='eval')
        return _eval_node(node.body)
    except SyntaxError:
        raise ValueError(f"Invalid syntax in expression: {expression}")


def _eval_node(node):
    if isinstance(node, ast.Constant):
        return node.value
    elif isinstance(node, ast.BinOp):
        left = _eval_node(node.left)
        right = _eval_node(node.right)
        op_type = type(node.op)
        if op_type in _OPERATORS:
            return _OPERATORS[op_type](left, right)
        else:
            raise ValueError(f"Unsupported operator: {op_type}")
    elif isinstance(node, ast.UnaryOp):
        operand = _eval_node(node.operand)
        op_type = type(node.op)
        if op_type in _OPERATORS:
            return _OPERATORS[op_type](operand)
        else:
            raise ValueError(f"Unsupported unary operator: {op_type}")
    else:
        raise ValueError(f"Unsupported expression node: {type(node)}")


if __name__ == "__main__":
    print(f"Result: {add(1, 2)}")
