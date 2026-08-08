class AppConfig {
  const AppConfig({
    required this.name,
    required this.useMocks,
    this.apiUrl = '',
  });

  final String name;
  final bool useMocks;
  final String apiUrl;
}
