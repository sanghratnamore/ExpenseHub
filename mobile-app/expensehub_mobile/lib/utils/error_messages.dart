String getFriendlyError(Object error) {
  final raw = error.toString()
      .replaceAll('Exception: ', '')
      .replaceAll('FormatException: ', '')
      .trim();

  if (raw.contains('SocketException') ||
      raw.contains('Failed host lookup')) {
    return 'No internet connection. Please try again.';
  }

  if (raw.contains('401')) {
    return 'Session expired. Please log in again.';
  }

  if (raw.contains('403')) {
    return 'You do not have permission for this action.';
  }

  if (raw.contains('404')) {
    return 'The requested item was not found.';
  }

  if (raw.contains('409')) {
    return raw;
  }

  if (raw.contains('500')) {
    return 'Something went wrong on the server. Please try again.';
  }

  return raw.isEmpty ? 'Something went wrong. Please try again.' : raw;
}