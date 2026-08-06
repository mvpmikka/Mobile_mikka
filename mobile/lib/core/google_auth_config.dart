class GoogleAuthConfig {
  const GoogleAuthConfig._();

  // Web OAuth client ID — a public identifier, not a secret, safe to embed
  // in app code. Passed as serverClientId so Google Sign-In issues an ID
  // token whose audience matches Backend's GOOGLE_CLIENT_ID, letting the
  // backend verify it server-side.
  static const String serverClientId =
      '850901436789-bppa7iivs4uidmjg0s1v2eqilnoapt0i.apps.googleusercontent.com';
}
