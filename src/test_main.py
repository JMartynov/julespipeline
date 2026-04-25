"""
Tests for the main basic math and expression evaluation module.
"""

import json
import pytest
from main import (
    add, subtract, multiply, divide, DivisionByZeroError, evaluate_expression,
    get_history, clear_history, import_history
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


def test_history_tracking():
    """Test that history is tracked during evaluations."""
    clear_history()
    assert not get_history()

    evaluate_expression("2 + 3")
    evaluate_expression("10 - 4")

    history = get_history()
    assert len(history) == 2
    assert history[0] == {"expression": "2 + 3", "result": 5}
    assert history[1] == {"expression": "10 - 4", "result": 6}

    clear_history()
    assert not get_history()


def test_import_history_valid(tmp_path):
    """Test importing a valid history JSON file."""
    clear_history()
    data = [
        {"expression": "1 + 1", "result": 2},
        {"expression": "2 * 3", "result": 6}
    ]
    file_path = tmp_path / "history.json"
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump(data, f)

    import_history(str(file_path))
    history = get_history()
    assert len(history) == 2
    assert history[0] == {"expression": "1 + 1", "result": 2}
    assert history[1] == {"expression": "2 * 3", "result": 6}


def test_import_history_file_not_found():
    """Test importing history from a non-existent file."""
    with pytest.raises(FileNotFoundError, match="File not found"):
        import_history("non_existent_file.json")


def test_import_history_invalid_json(tmp_path):
    """Test importing history from an invalid JSON file."""
    file_path = tmp_path / "invalid.json"
    with open(file_path, "w", encoding="utf-8") as f:
        f.write("{ invalid json ")

    with pytest.raises(ValueError, match="Invalid JSON format"):
        import_history(str(file_path))


def test_import_history_not_a_list(tmp_path):
    """Test importing history where root is not a list."""
    file_path = tmp_path / "not_list.json"
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump({"expression": "1 + 1", "result": 2}, f)

    with pytest.raises(
        ValueError, match="Invalid history format: expected a list"
    ):
        import_history(str(file_path))


def test_import_history_invalid_entry_type(tmp_path):
    """Test importing history where an entry is not a dictionary."""
    file_path = tmp_path / "invalid_entry.json"
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump([1, 2, 3], f)

    with pytest.raises(
        ValueError, match="Invalid history entry: expected a dictionary"
    ):
        import_history(str(file_path))


def test_import_history_missing_keys(tmp_path):
    """Test importing history where entries are missing required keys."""
    file_path = tmp_path / "missing_keys.json"
    with open(file_path, "w", encoding="utf-8") as f:
        json.dump([{"expression": "1 + 1"}], f)

    with pytest.raises(
        ValueError,
        match="Invalid history entry: missing 'expression' or 'result' keys"
    ):
        import_history(str(file_path))


def test_import_history_is_a_directory(tmp_path):
    """Test importing history where the path is a directory."""
    with pytest.raises(IsADirectoryError, match="Is a directory:"):
        import_history(str(tmp_path))
