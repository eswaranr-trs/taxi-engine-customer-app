class OAuthResult {
  final String? idToken;
  final String? accessToken;
  final String? refreshToken;
  final String? authorizationCode;

  const OAuthResult({this.idToken, this.accessToken, this.refreshToken, this.authorizationCode});
}

class OAuth2Config {
  OAuth2Config._();

  static const String clientId = 'TODO_CLIENT_ID';
  static const String redirectUri = 'TODO_REDIRECT_URI';
  static const String issuer = 'TODO_ISSUER_URL';
  static const String authorizationEndpoint = 'TODO_AUTH_ENDPOINT';
  static const String tokenEndpoint = 'TODO_TOKEN_ENDPOINT';
  static const List<String> scopes = ['openid', 'email', 'profile'];
}

class OAuth2Service {
  Future<OAuthResult> signIn() async {
    throw UnimplementedError('OAuth2Service.signIn not implemented yet.');
  }

  Future<Map<String, dynamic>?> exchangeWithBackend(OAuthResult result) async {
    throw UnimplementedError('OAuth2Service.exchangeWithBackend not implemented yet.');
  }

  Future<OAuthResult> refresh(String refreshToken) async {
    throw UnimplementedError('OAuth2Service.refresh not implemented yet.');
  }

  Future<void> signOut() async {
    throw UnimplementedError('OAuth2Service.signOut not implemented yet.');
  }
}
