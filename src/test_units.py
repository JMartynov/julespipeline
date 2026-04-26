"""
Tests for unit conversion functions.
"""

import decimal
import pytest
from units import convert


def test_convert_length():
    """Test length conversions."""
    # m to ft
    assert convert(1, "m", "ft") == 3.28084
    assert convert(decimal.Decimal("1"), "m",
                   "ft") == decimal.Decimal("3.28084")
    # ft to m
    assert convert(1, "ft", "m") == 0.3048
    assert convert(decimal.Decimal("1"), "ft",
                   "m") == decimal.Decimal("0.3048")


def test_convert_weight():
    """Test weight conversions."""
    # kg to lb
    assert convert(1, "kg", "lb") == 2.20462
    assert convert(decimal.Decimal("1"), "kg",
                   "lb") == decimal.Decimal("2.20462")
    # lb to kg
    assert convert(1, "lb", "kg") == 0.453592
    assert convert(decimal.Decimal("1"), "lb",
                   "kg") == decimal.Decimal("0.453592")


def test_convert_temperature():
    """Test temperature conversions."""
    # C to F
    assert convert(0, "C", "F") == 32.0
    assert convert(100, "C", "F") == 212.0
    assert convert(decimal.Decimal("0"), "C", "F") == decimal.Decimal("32")
    assert convert(decimal.Decimal("100"), "C", "F") == decimal.Decimal("212")
    # F to C
    assert convert(32, "F", "C") == 0.0
    assert convert(212, "F", "C") == 100.0
    assert convert(decimal.Decimal("32"), "F", "C") == decimal.Decimal("0")
    assert convert(decimal.Decimal("212"), "F", "C") == decimal.Decimal("100")


def test_convert_identity():
    """Test identity conversions."""
    assert convert(1, "m", "m") == 1
    assert convert(decimal.Decimal("1.5"), "m",
                   "m") == decimal.Decimal("1.5")
    assert convert(0, "C", "C") == 0


def test_convert_unsupported():
    """Test unsupported conversions."""
    with pytest.raises(ValueError, match="Unsupported conversion from x to y"):
        convert(1, "x", "y")
    with pytest.raises(ValueError, match="Unsupported conversion from x to x"):
        convert(1, "x", "x")
    match_str = "Unsupported conversion from m to kg"
    with pytest.raises(ValueError, match=match_str):
        convert(1, "m", "kg")
