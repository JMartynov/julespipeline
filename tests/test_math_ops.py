import pytest
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../src')))

from math_ops import add, subtract, multiply, divide, CustomZeroDivisionError

def test_add():
    assert add(2, 3) == 5
    assert add(-1, 1) == 0
    assert add(-1, -1) == -2
    assert add(0, 0) == 0
    assert add(1.5, 2.5) == 4.0

def test_subtract():
    assert subtract(5, 3) == 2
    assert subtract(1, 1) == 0
    assert subtract(-1, 1) == -2
    assert subtract(-1, -1) == 0
    assert subtract(5.5, 2.5) == 3.0

def test_multiply():
    assert multiply(2, 3) == 6
    assert multiply(-2, 3) == -6
    assert multiply(-2, -3) == 6
    assert multiply(0, 5) == 0
    assert multiply(1.5, 2) == 3.0

def test_divide():
    assert divide(6, 3) == 2.0
    assert divide(-6, 3) == -2.0
    assert divide(-6, -3) == 2.0
    assert divide(0, 5) == 0.0
    assert divide(5.0, 2.0) == 2.5

def test_divide_by_zero():
    with pytest.raises(CustomZeroDivisionError, match="Division by zero is not allowed."):
        divide(5, 0)

    with pytest.raises(CustomZeroDivisionError, match="Division by zero is not allowed."):
        divide(0, 0)
