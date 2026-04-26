# pylint: disable=cyclic-import
"""
Statistical functions for the calculator.
"""

import statistics


def _parse_input(data):
    """Parse the input data if it is a string."""
    if isinstance(data, str):
        # We import here to avoid circular imports
        # pylint: disable=import-outside-toplevel
        from main import evaluate_expression
        data = evaluate_expression(data)
    if not isinstance(data, list):
        raise ValueError(
            "Input must be a list or a string representing a list.")
    return data


def mean(data):
    """Return the sample arithmetic mean of data."""
    return statistics.mean(_parse_input(data))


def median(data):
    """Return the median (middle value) of data."""
    return statistics.median(_parse_input(data))


def mode(data):
    """Return the single most common data point from discrete or nominal data.
    """
    return statistics.mode(_parse_input(data))


def variance(data):
    """Return the sample variance of data."""
    return statistics.variance(_parse_input(data))


def standard_deviation(data):
    """Return the sample standard deviation of data."""
    return statistics.stdev(_parse_input(data))
