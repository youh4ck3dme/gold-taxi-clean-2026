abstract class LocalStorageService {
  Future<String?> getToken();
  Future<void> saveToken(String token);
  Future<void> deleteToken();
}
