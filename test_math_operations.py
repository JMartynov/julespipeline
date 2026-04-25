import pytest
from math_operations import add, subtract, multiply, divide, DivisionByZeroError

def test_add():
    assert add(1, 2) == 3
    assert add(-1, 1) == 0
    assert add(-1, -1) == -2
    assert add(0, 0) == 0
    assert add(1.5, 2.5) == 4.0

def test_subtract():
    assert subtract(2, 1) == 1
    assert subtract(-1, 1) == -2
    assert subtract(-1, -1) == 0
    assert subtract(0, 0) == 0
    assert subtract(2.5, 1.5) == 1.0

def test_multiply():
    assert multiply(2, 3) == 6
    assert multiply(-1, 1) == -1
    assert multiply(-1, -1) == 1
    assert multiply(0, 5) == 0
    assert multiply(1.5, 2.0) == 3.0

def test_divide():
    assert divide(6, 3) == 2.0
    assert divide(-4, 2) == -2.0
    assert divide(-4, -2) == 2.0
    assert divide(0, 5) == 0.0
    assert divide(5.0, 2.0) == 2.5

def test_divide_by_zero():
    with pytest.raises(DivisionByZeroError):
        divide(5, 0)

    with pytest.raises(DivisionByZeroError):
        divide(0, 0)
