"""
Tests for the main basic math and expression evaluation module.
"""

import decimal
import pytest
from main import (
    add, subtract, multiply, divide, DivisionByZeroError, evaluate_expression,
    CalculatorConfig
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

    # Unsupported operations (e.g. power, bitwise if not added)
    with pytest.raises(ValueError, match="Unsupported operator"):
        evaluate_expression("2 ** 3")
    with pytest.raises(ValueError, match="Unsupported operator"):
        evaluate_expression("2 | 3")

    # Division by zero via string evaluation
    with pytest.raises(DivisionByZeroError, match="Cannot divide by zero"):
        evaluate_expression("10 / 0")

    # Unsupported unary operations
    with pytest.raises(ValueError, match="Unsupported unary operator"):
        evaluate_expression("not 5")

    # Unsupported expression node
    from main import _eval_node  # pylint: disable=import-outside-toplevel
    import ast  # pylint: disable=import-outside-toplevel
    with pytest.raises(ValueError, match="Unsupported expression node"):
        _eval_node(ast.List(elts=[], ctx=ast.Load()), "")


def test_decimal_precision():
    """Test use_decimal evaluates to Decimal and avoids float issues."""
    # Temporarily enable decimal support
    CalculatorConfig.use_decimal = True
    try:
        result = evaluate_expression("0.1 + 0.2")
        assert isinstance(result, decimal.Decimal)
        assert result == decimal.Decimal("0.3")

        # Test multiplication
        res_mul = evaluate_expression("0.1 * 3")
        assert isinstance(res_mul, decimal.Decimal)
        assert res_mul == decimal.Decimal("0.3")

        # Test division
        res_div = evaluate_expression("1.0 / 3")
        assert isinstance(res_div, decimal.Decimal)

        # Test high precision
        res_high = evaluate_expression("0.1234567890123456789012345")
        assert isinstance(res_high, decimal.Decimal)
        assert str(res_high) == "0.1234567890123456789012345"

        # Test fallback where source_str isn't available
        # by passing an AST directly that didn't come from string
        # though evaluate_expression always uses string.
        # We can simulate by clearing the source segment info if we could,
        # but easier to test eval node direct.
        from main import _eval_node  # pylint: disable=import-outside-toplevel
        import ast  # pylint: disable=import-outside-toplevel,reimported
        node = ast.Constant(value=1.5)
        # Without expression source, it falls back to str(1.5)
        res_fallback = _eval_node(node, expression="")
        assert res_fallback == decimal.Decimal("1.5")

        # Test boolean ignoring
        assert evaluate_expression("True") is True

    finally:
        CalculatorConfig.use_decimal = False
