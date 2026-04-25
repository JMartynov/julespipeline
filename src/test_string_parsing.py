import pytest
from main import evaluate_expression, DivisionByZeroError


def test_evaluate_addition():
    assert evaluate_expression("2 + 3") == 5


def test_evaluate_subtraction():
    assert evaluate_expression("5 - 2") == 3


def test_evaluate_multiplication():
    assert evaluate_expression("4 * 3") == 12


def test_evaluate_division():
    assert evaluate_expression("10 / 2") == 5.0


def test_evaluate_order_of_operations():
    assert evaluate_expression("2 + 3 * 4") == 14
    assert evaluate_expression("10 - 4 / 2") == 8.0
    assert evaluate_expression("2 * 3 + 4 * 5") == 26


def test_evaluate_parentheses():
    assert evaluate_expression("(2 + 3) * 4") == 20
    assert evaluate_expression("10 / (2 + 3)") == 2.0
    assert evaluate_expression("((2 + 3) * 4) - 5") == 15


def test_evaluate_unary_operators():
    assert evaluate_expression("-5 + 3") == -2
    assert evaluate_expression("-(2 + 3)") == -5
    assert evaluate_expression("+5 + 3") == 8


def test_evaluate_division_by_zero():
    with pytest.raises(DivisionByZeroError):
        evaluate_expression("10 / 0")


def test_evaluate_invalid_expression():
    with pytest.raises(SyntaxError):
        evaluate_expression("2 + * 3")


def test_evaluate_unsupported_operator():
    with pytest.raises(ValueError, match="Unsupported operator"):
        evaluate_expression("2 ** 3")
