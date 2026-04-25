import pytest
from main import add, subtract, multiply, divide, DivisionByZeroError

def test_add():
    assert add(1, 2) == 3
    assert add(-1, 1) == 0
    assert add(-1, -1) == -2
    assert add(0, 0) == 0
    assert add(1000000, 2000000) == 3000000

def test_subtract():
    assert subtract(2, 1) == 1
    assert subtract(1, 2) == -1
    assert subtract(-1, -1) == 0
    assert subtract(0, 0) == 0

def test_multiply():
    assert multiply(2, 3) == 6
    assert multiply(-2, 3) == -6
    assert multiply(-2, -3) == 6
    assert multiply(0, 5) == 0

def test_divide():
    assert divide(6, 2) == 3.0
    assert divide(-6, 2) == -3.0
    assert divide(-6, -2) == 3.0
    assert divide(0, 5) == 0.0
    assert divide(5, 2) == 2.5

def test_divide_by_zero():
    with pytest.raises(DivisionByZeroError) as excinfo:
        divide(10, 0)
    assert "Cannot divide by zero" in str(excinfo.value)
