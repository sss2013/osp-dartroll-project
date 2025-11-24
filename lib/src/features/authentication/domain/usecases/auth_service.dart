import 'package:cultureyo/src/features/authentication/domain/entities/auth_data.dart';
enum TokenStatus {
  valid,
  expired,
  timeMisMatch,
  tokenMisMatch,
  networkError,

}
abstract class AuthService {
  Future<AuthData?> login();
  Future<TokenStatus> checkToken();
  Future<AuthData?> refreshToken();
  Future<bool> sendTokenToServer(AuthData data);
}