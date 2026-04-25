class DivisionByZeroError(Exception):
    """Custom exception for division by zero."""
    pass

def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise DivisionByZeroError("Cannot divide by zero.")
    return a / b
