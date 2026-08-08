class AppConfig {
  const AppConfig({
    required this.name,
    required this.useMocks,
    this.useLocalDatabase = false,
    this.apiUrl = '',
  });

  final String name;
  final bool useMocks;
  final bool useLocalDatabase;
  final String apiUrl;
}
