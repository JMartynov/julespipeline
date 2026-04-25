class DivisionByZeroError(Exception):
    """Custom exception raised for division by zero."""
    pass

def add(a, b):
    return a + b

def subtract(a, b):
    return a - b

def multiply(a, b):
    return a * b

def divide(a, b):
    if b == 0:
        raise DivisionByZeroError("Cannot divide by zero")
    return a / b

if __name__ == "__main__":
    print(f"Result: {add(1, 2)}")
