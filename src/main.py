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


def _eval_node(node):
    if isinstance(node, ast.Constant):
        return node.value
    elif isinstance(node, ast.BinOp):
        left = _eval_node(node.left)
        right = _eval_node(node.right)
        if isinstance(node.op, ast.Add):
            return add(left, right)
        elif isinstance(node.op, ast.Sub):
            return subtract(left, right)
        elif isinstance(node.op, ast.Mult):
            return multiply(left, right)
        elif isinstance(node.op, ast.Div):
            return divide(left, right)
        else:
            raise ValueError(f"Unsupported operator: {type(node.op)}")
    elif isinstance(node, ast.UnaryOp):
        if isinstance(node.op, ast.USub):
            return subtract(0, _eval_node(node.operand))
        elif isinstance(node.op, ast.UAdd):
            return _eval_node(node.operand)
        else:
            raise ValueError(f"Unsupported operator: {type(node.op)}")
    else:
        raise ValueError(f"Unsupported expression: {type(node)}")


def evaluate_expression(expression):
    node = ast.parse(expression, mode='eval')
    return _eval_node(node.body)


if __name__ == "__main__":
    print(f"Result: {add(1, 2)}")
