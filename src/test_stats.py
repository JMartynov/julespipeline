"""
Tests for the statistical functions.
"""

import pytest
from stats import mean, median, mode, variance, standard_deviation, _parse_input


def test_parse_input():
    """Test parsing logic."""
    assert _parse_input([1, 2, 3]) == [1, 2, 3]
    assert _parse_input("[1, 2, 3]") == [1, 2, 3]
    with pytest.raises(ValueError, match="Input must be a list"):
        _parse_input("1 + 2")


def test_mean():
    """Test mean function."""
    assert mean([1, 2, 3]) == 2
    assert mean("[1, 2, 3]") == 2
    assert mean([1.5, 2.5, 3.5]) == 2.5


def test_median():
    """Test median function."""
    assert median([1, 3, 2]) == 2
    assert median("[1, 3, 2]") == 2
    assert median([1, 2, 3, 4]) == 2.5


def test_mode():
    """Test mode function."""
    assert mode([1, 2, 2, 3]) == 2
    assert mode("[1, 2, 2, 3]") == 2


def test_variance():
    """Test variance function."""
    assert variance([1, 2, 3]) == 1.0
    assert variance("[1, 2, 3]") == 1.0


def test_standard_deviation():
    """Test standard deviation function."""
    assert standard_deviation([1, 2, 3]) == 1.0
    assert standard_deviation("[1, 2, 3]") == 1.0
