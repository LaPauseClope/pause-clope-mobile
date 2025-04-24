class Validators {
  static bool isValidNickname(String nickname) {
    return nickname.trim().isNotEmpty && nickname.length >= 3;
  }

  static bool isShortNickname(String nickname) {
    return nickname.trim().length < 5;
  }
}
