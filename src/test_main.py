"""
Tests for the main basic math and expression evaluation module.
"""

import logging
import pytest
from main import (
    add, subtract, multiply, divide, DivisionByZeroError, evaluate_expression
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


def test_divide_by_zero(caplog):
    """Test divide raises DivisionByZeroError appropriately and logs it."""
    with pytest.raises(DivisionByZeroError) as excinfo:
        divide(10, 0)
    assert "Cannot divide by zero" in str(excinfo.value)
    assert any(
        record.levelno == logging.ERROR and
        "Cannot divide by zero" in record.message
        for record in caplog.records
    )


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


def test_logging_info(caplog):
    """Test that evaluate_expression logs INFO with the correct message."""
    with caplog.at_level(logging.INFO):
        evaluate_expression("2 + 3")
        assert any(
            record.levelno == logging.INFO and
            "Calculated 2 + 3 = 5" in record.message
            for record in caplog.records
        )


def test_logging_error_invalid_syntax(caplog):
    """Test that evaluate_expression logs ERROR for invalid syntax."""
    with caplog.at_level(logging.ERROR):
        with pytest.raises(ValueError):
            evaluate_expression("2 + * 3")
        assert any(
            record.levelno == logging.ERROR and
            "Invalid syntax in expression: 2 + * 3" in record.message
            for record in caplog.records
        )


def test_logging_error_division_by_zero(caplog):
    """Test that evaluate_expression logs ERROR for division by zero."""
    with caplog.at_level(logging.ERROR):
        with pytest.raises(DivisionByZeroError):
            evaluate_expression("10 / 0")
        assert any(
            record.levelno == logging.ERROR and
            "Error evaluating 10 / 0: Cannot divide by zero" in record.message
            for record in caplog.records
        )


def test_evaluate_unsupported_operator(caplog):
    """Test unsupported binary operator logs ERROR."""
    with caplog.at_level(logging.ERROR):
        with pytest.raises(ValueError, match="Unsupported operator"):
            evaluate_expression("2 ** 3")
        assert any(
            record.levelno == logging.ERROR and
            "Error evaluating 2 ** 3: Unsupported operator" in record.message
            for record in caplog.records
        )


def test_evaluate_unsupported_unary_operator(caplog):
    """Test unsupported unary operator logs ERROR."""
    with caplog.at_level(logging.ERROR):
        with pytest.raises(ValueError, match="Unsupported unary operator"):
            evaluate_expression("~5")
        assert any(
            record.levelno == logging.ERROR and
            "Error evaluating ~5: Unsupported unary operator" in record.message
            for record in caplog.records
        )


def test_evaluate_unsupported_expression_node(caplog):
    """Test unsupported expression node logs ERROR."""
    with caplog.at_level(logging.ERROR):
        with pytest.raises(ValueError, match="Unsupported expression node"):
            evaluate_expression("x")
        assert any(
            record.levelno == logging.ERROR and
            "Error evaluating x: Unsupported expression node" in record.message
            for record in caplog.records
        )
