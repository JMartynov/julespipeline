"""
Tests for the main basic math and expression evaluation module.
"""

import ast
import math
import pytest
from main import (
    add, subtract, multiply, divide, power, sqrt, log, DivisionByZeroError,
    evaluate_expression, _eval_node
)


def test_add():
    """Test the add function."""
    assert add(1, 2) == 3
    assert add(-1, 1) == 0
    assert add(-1, -1) == -2
    assert add(0, 0) == 0
    assert add(1000000, 2000000) == 3000000


def test_subtract():
    """Test the subtract function."""
    assert subtract(2, 1) == 1
    assert subtract(1, 2) == -1
    assert subtract(-1, -1) == 0
    assert subtract(0, 0) == 0


def test_multiply():
    """Test the multiply function."""
    assert multiply(2, 3) == 6
    assert multiply(-2, 3) == -6
    assert multiply(-2, -3) == 6
    assert multiply(0, 5) == 0


def test_divide():
    """Test the divide function."""
    assert divide(6, 2) == 3.0
    assert divide(-6, 2) == -3.0
    assert divide(-6, -2) == 3.0
    assert divide(0, 5) == 0.0
    assert divide(5, 2) == 2.5


def test_divide_by_zero():
    """Test that divide raises DivisionByZeroError appropriately."""
    with pytest.raises(DivisionByZeroError) as excinfo:
        divide(10, 0)
    assert "Cannot divide by zero" in str(excinfo.value)


def test_power():
    """Test the power function."""
    assert power(2, 3) == 8
    assert power(5, 0) == 1
    assert power(-2, 3) == -8
    assert power(2, -1) == 0.5

    with pytest.raises(
        ValueError, match="Cannot raise zero to a negative power"
    ):
        power(0, -1)

    with pytest.raises(
        ValueError,
        match="Cannot raise a negative number to a non-integer power"
    ):
        power(-2, 0.5)


def test_sqrt():
    """Test the sqrt function."""
    assert sqrt(16) == 4.0
    assert sqrt(0) == 0.0
    assert sqrt(2.25) == 1.5

    with pytest.raises(
        ValueError, match="Cannot calculate square root of a negative number"
    ):
        sqrt(-1)


def test_log():
    """Test the log function."""
    # Natural log by default
    assert math.isclose(log(math.e), 1.0)

    # Custom base
    assert math.isclose(log(100, 10), 2.0)
    assert math.isclose(log(8, 2), 3.0)

    msg_non_pos = "Cannot calculate logarithm of a non-positive number"
    with pytest.raises(ValueError, match=msg_non_pos):
        log(0)
    with pytest.raises(ValueError, match=msg_non_pos):
        log(-5)

    msg_base = "Logarithm base must be positive and not equal to 1"
    with pytest.raises(ValueError, match=msg_base):
        log(10, 0)
    with pytest.raises(ValueError, match=msg_base):
        log(10, -2)
    with pytest.raises(ValueError, match=msg_base):
        log(10, 1)


def test_evaluate_expression():
    """Test the evaluate_expression function for various math expressions."""
    # Basic operations
    assert evaluate_expression("2 + 3") == 5
    assert evaluate_expression("10 - 4") == 6
    assert evaluate_expression("3 * 4") == 12
    assert evaluate_expression("10 / 2") == 5.0

    # Precedence and parenthesis
    assert evaluate_expression("2 + 3 * 4") == 14
    assert evaluate_expression("(2 + 3) * 4") == 20
    assert evaluate_expression("10 / 2 - 1") == 4.0

    # Unary operations
    assert evaluate_expression("-5 + 3") == -2
    assert evaluate_expression("+5") == 5
    assert evaluate_expression("-(2 + 3)") == -5

    # Invalid syntax
    with pytest.raises(ValueError, match="Invalid syntax"):
        evaluate_expression("2 + * 3")

    # Advanced math operations
    assert evaluate_expression("2 ** 3") == 8
    assert evaluate_expression("sqrt(16)") == 4.0
    assert evaluate_expression("sqrt(16) + 2") == 6.0
    assert math.isclose(evaluate_expression("log(100, 10)"), 2.0)
    # approx math.e
    assert math.isclose(evaluate_expression("log(2.718281828459045)"), 1.0)

    # Advanced math operations errors
    msg_sqrt_neg = "Cannot calculate square root of a negative number"
    with pytest.raises(ValueError, match=msg_sqrt_neg):
        evaluate_expression("sqrt(-1)")
    with pytest.raises(ValueError, match="sqrt expects exactly 1 argument"):
        evaluate_expression("sqrt(16, 2)")

    msg_log_neg = "Cannot calculate logarithm of a non-positive number"
    with pytest.raises(ValueError, match=msg_log_neg):
        evaluate_expression("log(-10, 10)")
    with pytest.raises(ValueError, match="log expects 1 or 2 arguments"):
        evaluate_expression("log(100, 10, 2)")
    with pytest.raises(ValueError, match="Unsupported unary operator"):
        evaluate_expression("~5")

    with pytest.raises(ValueError, match="Unsupported function call"):
        evaluate_expression("unknown_func(10)")

    with pytest.raises(ValueError, match="Unsupported expression node"):
        evaluate_expression("[]")

    # Unsupported operations (e.g. bitwise if not added)
    with pytest.raises(ValueError, match="Unsupported operator"):
        evaluate_expression("2 | 3")

    # Division by zero via string evaluation
    with pytest.raises(DivisionByZeroError, match="Cannot divide by zero"):
        evaluate_expression("10 / 0")


def test_unsupported_ast_nodes():
    """Test evaluating unsupported AST nodes manually."""
    with pytest.raises(ValueError, match="Unsupported function call"):
        _eval_node(ast.Call(func=ast.Constant(value=1), args=[]))
