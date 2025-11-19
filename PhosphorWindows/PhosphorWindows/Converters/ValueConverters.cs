using System;
using System.Globalization;
using Avalonia.Data.Converters;
using PhosphorWindows.Models;

namespace PhosphorWindows.Converters;

public class EnumToIndexConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is Enum enumValue)
        {
            return System.Convert.ToInt32(enumValue);
        }
        return 0;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int index && targetType.IsEnum)
        {
            return Enum.ToObject(targetType, index);
        }
        return null;
    }
}

public class GreaterThanConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue && parameter is string paramStr && int.TryParse(paramStr, out int compareValue))
        {
            return intValue > compareValue;
        }
        return false;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class AddOneConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue)
        {
            return intValue + 1;
        }
        return value;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue)
        {
            return intValue - 1;
        }
        return value;
    }
}

public class SubtractOneConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue)
        {
            return Math.Max(0, intValue - 1);
        }
        return 0;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class PlayPauseTextConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is bool isPlaying)
        {
            return isPlaying ? "⏸" : "▶";
        }
        return "▶";
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class NotNullConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        return value != null;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class IsZeroConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue)
        {
            return intValue == 0;
        }
        return false;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is bool boolValue)
        {
            return boolValue ? 0 : 1;
        }
        return 0;
    }
}

public class NotZeroConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue)
        {
            return intValue != 0;
        }
        return true;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}

public class PercentageConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is double doubleValue)
        {
            return (int)(doubleValue * 100);
        }
        return 0;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is int intValue)
        {
            return intValue / 100.0;
        }
        return 0.0;
    }
}

public class IsCustomModeConverter : IValueConverter
{
    public object? Convert(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        if (value is ResizeMode mode)
        {
            return mode == ResizeMode.Custom;
        }
        return false;
    }

    public object? ConvertBack(object? value, Type targetType, object? parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
