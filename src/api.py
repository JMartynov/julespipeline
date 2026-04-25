"""
REST API for the calculator using FastAPI.
"""
from typing import List, Dict, Any
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

from src.main import (
    add, subtract, multiply, divide, DivisionByZeroError, evaluate_expression
)

app = FastAPI(title="Calculator API")

# Memory tracking calculation history
history: List[Dict[str, Any]] = []


class EvaluateRequest(BaseModel):
    """Request model for evaluate endpoint."""
    expression: str


@app.get("/add")
def api_add(a: float, b: float):
    """Add two numbers."""
    result = add(a, b)
    expression = f"{a} + {b}"
    history.append({"expression": expression, "result": result})
    return {"expression": expression, "result": result}


@app.get("/subtract")
def api_subtract(a: float, b: float):
    """Subtract two numbers."""
    result = subtract(a, b)
    expression = f"{a} - {b}"
    history.append({"expression": expression, "result": result})
    return {"expression": expression, "result": result}


@app.get("/multiply")
def api_multiply(a: float, b: float):
    """Multiply two numbers."""
    result = multiply(a, b)
    expression = f"{a} * {b}"
    history.append({"expression": expression, "result": result})
    return {"expression": expression, "result": result}


@app.get("/divide")
def api_divide(a: float, b: float):
    """Divide two numbers."""
    try:
        result = divide(a, b)
        expression = f"{a} / {b}"
        history.append({"expression": expression, "result": result})
        return {"expression": expression, "result": result}
    except DivisionByZeroError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.post("/evaluate")
def api_evaluate(request: EvaluateRequest):
    """Evaluate a math expression."""
    try:
        result = evaluate_expression(request.expression)
        history.append({"expression": request.expression, "result": result})
        return {"expression": request.expression, "result": result}
    except (ValueError, DivisionByZeroError) as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@app.get("/history")
def api_history():
    """Retrieve calculation history."""
    return history
