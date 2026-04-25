class CustomZeroDivisionError(Exception):
    """Exception raised when attempting to divide by zero."""
    pass

def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise CustomZeroDivisionError("Division by zero is not allowed.")
    return a / b
