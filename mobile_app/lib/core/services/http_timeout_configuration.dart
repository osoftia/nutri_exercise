/// Process-wide HTTP timeout value observed dynamically by API services.
class HttpTimeoutConfiguration {
  HttpTimeoutConfiguration._();

  static const int minimumSeconds = 10;
  static const int maximumSeconds = 60;
  static const int defaultSeconds = 60;

  static int _seconds = defaultSeconds;

  static int get currentSeconds => _seconds;

  static Duration get currentTimeout => Duration(seconds: _seconds);

  static void setSeconds(int seconds) {
    if (seconds < minimumSeconds || seconds > maximumSeconds) {
      throw RangeError.range(
        seconds,
        minimumSeconds,
        maximumSeconds,
        'seconds',
      );
    }
    _seconds = seconds;
  }

  /// Resets process configuration for an isolated test or app bootstrap.
  static void reset() => _seconds = defaultSeconds;
}
