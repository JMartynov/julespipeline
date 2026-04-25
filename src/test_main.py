"""
Tests for the main basic math and expression evaluation module.
"""

import unittest.mock
import pytest
from main import (
    add, subtract, multiply, divide, DivisionByZeroError, evaluate_expression,
    export_history_to_json
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


def test_export_history_to_json_success():
    """Test successful export of history to JSON."""
    history = [{"expression": "1 + 1", "result": 2}]
    filepath = "dummy_path.json"

    mocked_open = unittest.mock.mock_open()
    with unittest.mock.patch("builtins.open", mocked_open):
        export_history_to_json(history, filepath)

    mocked_open.assert_called_once_with(filepath, 'w', encoding='utf-8')
    # Check that json.dump was called by looking at write calls
    # or by mocking json.dump directly. However, write calls are simpler.
    # The string will have formatting since indent=4 is used.
    handle = mocked_open()
    # just ensure write was called
    assert handle.write.called


def test_export_history_to_json_ioerror():
    """Test IOError handling during export to JSON."""
    history = [{"expression": "2 + 2", "result": 4}]
    filepath = "dummy_path.json"

    mocked_open = unittest.mock.mock_open()
    mocked_open.side_effect = IOError("Permission denied")

    with unittest.mock.patch("builtins.open", mocked_open):
        err_msg = f"Failed to write history to {filepath}: Permission denied"
        with pytest.raises(IOError, match=err_msg):
            export_history_to_json(history, filepath)
