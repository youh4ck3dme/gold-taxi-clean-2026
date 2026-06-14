bool isGoogleMapsInitialized() {
  return const String.fromEnvironment('GOOGLE_MAPS_API_KEY').isNotEmpty;
}

Future<bool> ensureGoogleMapsInitialized() async {
  return isGoogleMapsInitialized();
}
