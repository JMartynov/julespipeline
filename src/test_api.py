"""
Tests for the REST API module.
"""
import pytest
from fastapi.testclient import TestClient
from src.api import app, history

client = TestClient(app)


@pytest.fixture(autouse=True)
def clear_history():
    """Clear the calculation history before each test."""
    history.clear()
    yield


def test_api_add():
    """Test the /add endpoint."""
    response = client.get("/add?a=10&b=5")
    assert response.status_code == 200
    assert response.json() == {"expression": "10.0 + 5.0", "result": 15.0}


def test_api_subtract():
    """Test the /subtract endpoint."""
    response = client.get("/subtract?a=10&b=5")
    assert response.status_code == 200
    assert response.json() == {"expression": "10.0 - 5.0", "result": 5.0}


def test_api_multiply():
    """Test the /multiply endpoint."""
    response = client.get("/multiply?a=10&b=5")
    assert response.status_code == 200
    assert response.json() == {"expression": "10.0 * 5.0", "result": 50.0}


def test_api_divide():
    """Test the /divide endpoint."""
    response = client.get("/divide?a=10&b=2")
    assert response.status_code == 200
    assert response.json() == {"expression": "10.0 / 2.0", "result": 5.0}


def test_api_divide_by_zero():
    """Test the /divide endpoint with division by zero."""
    response = client.get("/divide?a=10&b=0")
    assert response.status_code == 400
    assert "Cannot divide by zero" in response.json()["detail"]


def test_api_evaluate_success():
    """Test the /evaluate endpoint with valid expression."""
    response = client.post("/evaluate", json={"expression": "10 + 5 * 2"})
    assert response.status_code == 200
    assert response.json() == {"expression": "10 + 5 * 2", "result": 20.0}


def test_api_evaluate_invalid_syntax():
    """Test the /evaluate endpoint with invalid expression."""
    response = client.post("/evaluate", json={"expression": "10 + * 5"})
    assert response.status_code == 400
    assert "Invalid syntax" in response.json()["detail"]


def test_api_evaluate_divide_by_zero():
    """Test the /evaluate endpoint with division by zero."""
    response = client.post("/evaluate", json={"expression": "10 / 0"})
    assert response.status_code == 400
    assert "Cannot divide by zero" in response.json()["detail"]


def test_api_history():
    """Test the /history endpoint."""
    client.get("/add?a=1&b=2")
    client.post("/evaluate", json={"expression": "3 * 4"})

    response = client.get("/history")
    assert response.status_code == 200
    history_data = response.json()
    assert len(history_data) == 2
    assert history_data[0] == {"expression": "1.0 + 2.0", "result": 3.0}
    assert history_data[1] == {"expression": "3 * 4", "result": 12.0}
