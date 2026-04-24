/// Thrown when a user attempts to log in but their account has not yet been
/// verified via OTP. The backend returns HTTP 403 with `needsVerification: true`
/// and includes the `userId` so the client can redirect directly to the OTP
/// verification screen without requiring the user to re-enter their email.
class UnverifiedAccountException implements Exception {
  final String userId;
  final String message;

  const UnverifiedAccountException({
    required this.userId,
    required this.message,
  });

  @override
  String toString() => 'UnverifiedAccountException: $message (userId: $userId)';
}
