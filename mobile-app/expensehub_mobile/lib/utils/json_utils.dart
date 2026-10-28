class JsonUtils {
  static String parseId(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static String? parseOptionalId(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static String parseString(
    dynamic value, {
    String fallback = '',
  }) {
    return value?.toString() ?? fallback;
  }

  static String? parseOptionalString(dynamic value) {
    return value?.toString();
  }

  static double parseDouble(
    dynamic value, {
    double fallback = 0,
  }) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool parseBool(
    dynamic value, {
    bool fallback = false,
  }) {
    if (value is bool) return value;
    return value?.toString().toLowerCase() == 'true';
  }
}