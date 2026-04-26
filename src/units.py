"""
Unit conversion functions.
"""
import decimal


def convert(value, from_unit, to_unit):
    # pylint: disable=too-many-return-statements
    """
    Convert a value between units.
    Supported conversions: Length (m to ft), Weight (kg to lb),
    and Temperature (C to F).
    Raises ValueError for unsupported conversions.
    """
    is_decimal = isinstance(value, decimal.Decimal)

    if from_unit == "m" and to_unit == "ft":
        factor = decimal.Decimal("3.28084") if is_decimal else 3.28084
        return value * factor

    if from_unit == "ft" and to_unit == "m":
        factor = decimal.Decimal("0.3048") if is_decimal else 0.3048
        return value * factor

    if from_unit == "kg" and to_unit == "lb":
        factor = decimal.Decimal("2.20462") if is_decimal else 2.20462
        return value * factor

    if from_unit == "lb" and to_unit == "kg":
        factor = decimal.Decimal("0.453592") if is_decimal else 0.453592
        return value * factor

    if from_unit == "C" and to_unit == "F":
        if is_decimal:
            return value * decimal.Decimal("9") / decimal.Decimal("5") + \
                decimal.Decimal("32")
        return value * 9 / 5 + 32

    if from_unit == "F" and to_unit == "C":
        if is_decimal:
            return (value - decimal.Decimal("32")) * decimal.Decimal("5") / \
                decimal.Decimal("9")
        return (value - 32) * 5 / 9

    raise ValueError(f"Unsupported conversion from {from_unit} to {to_unit}")
